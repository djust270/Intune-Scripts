$jsonRepresentation = '{
   "checksum": "8a83fd48cdea66f88b0dcf708bceae47",
   "roots": {
      "bookmark_bar": {
         "children": [ {
            "date_added": "13218554400308142",
            "guid": "278dff65-0d68-4b8d-9cf8-60ea3b2dbe9d",
            "id": "5",
            "name": "Google",
            "type": "url",
            "url": "google.com"
         }, {
            "date_added": "13218554442843596",
            "guid": "3d87584d-a71f-4ff0-aa18-0c79efcc29c7",
            "id": "6",
            "name": "Reddit",
            "type": "url",
            "url": "Reddit.com"
         }, {
            "date_added": "13218554452536920",
            "guid": "179fa996-6b4b-4d9a-beb7-de96fa0d848a",
            "id": "7",
            "name": "Adobe",
            "type": "url",
            "url": "http://Adobe.com"
         }, {
            "date_added": "13218554465874578",
            "guid": "c03a072c-9956-4429-9737-cc770ecd34c5",
            "id": "8",
            "name": "Office 365 Portal",
            "type": "url",
            "url": "http://portal.office.com/"
         }, {
            "date_added": "13218554481458818",
            "guid": "a567e83d-8560-4de0-a03d-53c0dbb90cb4",
            "id": "9",
            "name": "My Apps",
            "type": "url",
            "url": "http://myapps.microsoft.com/"
         } ],
         "date_added": "13218553204407005",
         "date_modified": "13218554481458818",
         "guid": "00000000-0000-4000-A000-000000000002",
         "id": "1",
         "name": "Bookmarks bar",
         "type": "folder"
      },
      "other": {
         "children": [  ],
         "date_added": "13218553204407488",
         "date_modified": "0",
         "guid": "00000000-0000-4000-A000-000000000003",
         "id": "2",
         "name": "Other bookmarks",
         "type": "folder"
      },
      "synced": {
         "children": [  ],
         "date_added": "13218553204407497",
         "date_modified": "0",
         "guid": "00000000-0000-4000-A000-000000000004",
         "id": "3",
         "name": "Mobile bookmarks",
         "type": "folder"
      }
   },
   "version": 1
}'


$users = Get-ChildItem "C:\Users" -Exclude Public
$users | ForEach-Object {
New-Item -ItemType Directory -Path "C:\Users\$($_.Name)\AppData\Local\Google\chrome\User Data\default" -force 
Add-Content -path "C:\Users\$($_.Name)\AppData\Local\Google\chrome\User Data\default\bookmarks" $jsonRepresentation | ConvertTo-Json}
