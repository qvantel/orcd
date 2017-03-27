#!/usr/bin/env python3
import requests
import json
import re

#HTTP Request data
#projectId = '278035678015737' #Sprint 1
projectId = '297767546500356' #Sprint 2

url = 'https://app.asana.com/api/1.0/projects/'+projectId+'/tasks?opt_expand=this'
headr = {'Authorization': 'Bearer 0/5365430af91365ad8b0df5a4d0a07078'}

#Counters
completedPoints = 0.0
completedPercentageStr = ''
totalPoints = 0.0
unestimatedTasks = 0

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
        taskPoints = float(regmatch.group(1))#Parse the story points for the task
        totalPoints += taskPoints
        if(task['completed']):
            completedPoints += taskPoints  #if task is completed, add points to complete count
    else:
        unestimatedTasks += 1 #If the task did not have an estimation

#Calculate the percentage of completed points
if (totalPoints > 0):
    completedPercentageStr = " (" + '%.1f'%(100.0 * completedPoints / totalPoints) + "%)"

#Print the result
print('Total: ', totalPoints)
print('Completed: ', completedPoints, completedPercentageStr)
print('Amount of unestimated tasks: ', unestimatedTasks)
