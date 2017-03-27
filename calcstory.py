import requests
import json
import re

#HTTP Request data
url = 'https://app.asana.com/api/1.0/projects/297767546500356/tasks?opt_expand=this'
headr = {'Authorization': 'Bearer 0/5365430af91365ad8b0df5a4d0a07078'}

#Counters
completedPoints = 0
totalPoints = 0

#Regex to find a number within parentheses. Dots also allowed e.g (3.4)
regex = r".*?\(([0-9\.]+)\).*?" 

print('Fetching and calculating story points for sprint...')

#Send the request and save the response
response = requests.get(url, headers=headr);

#Parse the JSON list of all tasks
taskList = json.loads(response.text)['data']

#Loop the tasklist and count the total and completed points
for task in taskList:
  regmatch = re.search(regex, task['name'])#Search for regex match within the task name
  if(regmatch):
    taskPoints = float(regmatch.group(1))#Get the amount of points for the task
    totalPoints += taskPoints #Add it to the total
    if(task['completed']):
      completedPoints += taskPoints  #if task is completed, add points to complete count

#Print the result
print('Total: ', totalPoints)
print('Completed: ', completedPoints)