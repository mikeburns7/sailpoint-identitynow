#https://developer.sailpoint.com/idn/api/v3/search

import csv
import requests
import json
import datetime

# Create CSV for logging        
with open("/usr/local/google/home/miburns/projects/identitynow/users-removed-from-rolesv3.csv", "w", newline="") as csvfile:
    # Create a CSV writer object
    writer = csv.writer(csvfile)
    # Write the header row
    writer.writerow(["timestamp", "user","identityid","role","roleid" "outcome", "details"])

    # Prompt user for Access Token
    ACCESS_TOKEN = input('Enter Access Token:')

    headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': f'Bearer {ACCESS_TOKEN}'
    }

    payload = json.dumps({
        "indices": [
            "identities"
        ],
        "query": {
            "query": "roleCount:[1 TO 10] AND attributes.cloudLifecycleState:\"inactive\""
        },
        "queryResultFilter": {
            "includes": [
                "name",
                "displayName",
                "email",
                "id"
            ]
        }
    })

    url = "https://tenant.api.identitynow.com/v3/search"



    identities = requests.request("POST", url, headers=headers, data=payload)

    #print(response.text)

    json_identities = identities.json()

    for identity in json_identities:
        #print(identity["id"])
        identityid = identity["id"]

        payload = json.dumps({
            "indices": [
                "identities"
            ],
            "query": {
                "query": f"id:\"{identityid}\"",
                "innerHit":{
                    "type": "access",
                    "query": "type: \"ROLE\""
                }
            }
        })
        url = "https://tenant.api.identitynow.com/v3/search"
        roles = requests.request("POST", url, headers=headers, data=payload)

        json_roles = roles.json()
        
        #print (roles.text)

        for role in json_roles:
            #print(role["id"])

            roleid = role["id"]

            payload = json.dumps({
                "requestType": "REVOKE_ACCESS",
                "requestedFor": [
                    f"{identityid}"
                ],
                "requestedItems": [
                    {
                    "comment": "Removed by Workflow Leaver Remove Roles",
                    "id": f"{roleid}",
                    "type": "ROLE"
                    }
                ]       
            })

            url = "https://tenant.api.identitynow.com/v3/access-requests"

            deleted_role = requests.request("POST", url, headers=headers, data=payload)
            # Check the response status code & log to csv
            if deleted_role.status_code == 202:
                # Success!
                writer.writerow([datetime.datetime.now(),identity["email"],identityid,role["displayName"],roleid, "Deleted", "None"])
                
            else:
                # Error!
                writer.writerow([datetime.datetime.now(),identity["email"],identityid,role["displayName"],roleid,"error", deleted_role.text])
