#https://developer.sailpoint.com/idn/api/beta/delete-identity

import csv
import requests
import json
import datetime

# Prompt user for Access Token
ACCESS_TOKEN = input('Enter Access Token:')

# Open the CSV file
with open('ids-to-delround2.csv', 'r') as file:
    # Create a CSV reader object
    reader = csv.reader(file)
    # Skip the header row
    next(reader)

    # Create CSV for logging        
    with open("deleted_identities.csv", "w", newline="") as csvfile:
    # Create a CSV writer object
        writer = csv.writer(csvfile)
        # Write the header row
        writer.writerow(["timestamp", "user", "outcome", "details"])   
    

        # Make an HTTP call for each identity from CSV
        for row in reader:
            identityId = row[0]
            upn = row[1]

            # Construct the URI
            delacct = f'https://xxx.api.identitynow.com/beta/identities/{identityId}'
            
            # create http header with access token
            headers = {
            'Authorization': f'Bearer {ACCESS_TOKEN}',
            'Accept': 'application/json'
            }
            
            # Make the HTTP call - DELETE Identity
            response = requests.request("DELETE", delacct, headers=headers)

            # Check the response status code & log to csv
            if response.status_code == 204:
                # Success!
                writer.writerow([datetime.datetime.now(), upn, "Deleted", None])
                
            else:
                # Error!
                writer.writerow([datetime.datetime.now(), upn, "error", response.text])
