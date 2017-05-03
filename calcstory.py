#!/usr/bin/env python3
import requests
import json
import re

#HTTP Request data
#projectId = '278035678015737' #Sprint 1
#projectId = '297767546500356' #Sprint 2
#projectId = '314287247044636' #Sprint 3
projectId = '331864384586068' #Sprint 4

# Which tags to compare points for.
tags = {'Front end': 0, 'Back end': 0, 'Planning': 0}
other = 0

url = 'https://app.asana.com/api/1.0/projects/'+projectId+'/tasks?opt_expand=this'
headr = {'Authorization': 'Bearer 0/5365430af91365ad8b0df5a4d0a07078'}

#Counters
totalPoints = 0.0
completedPoints = 0.0
completedPercentageStr = ''

effortPoints = 0.0
completedEffortPoints = 0.0
completedEffortPercentageStr =''

effortByEstimationPercentageStr = ''

unestimatedTasks = 0

#Regex
regex = r'.*?\(([0-9\.]+)\).*?' #Find a number within parentheses (). Dots also allowed e.g (3.4)
regexEffort = r'.*?\[([0-9\.]+)\].*?'  #Find a number within brackets []. Dots also allowed e.g [3.4]

#Generate a percentage from dividend and divisor. e.g (30%)
def getPercentageStr (dividend, divisor):
    returnVal = ''
    if (divisor > 0):
        returnVal = "(" + '%.1f'%(100.0 * dividend / divisor) + "%)"
    return returnVal

#Logic starts here
print('Fetching and calculating story points for sprint...')

#Send the request and save the response
response = requests.get(url, headers=headr);

#Parse the JSON list of all tasks
taskList = json.loads(response.text)['data']

#Loop the tasklist and count the total and completed points
for task in taskList:
    ##Estimations
    regmatch = re.search(regex, task['name'])#Search for regex match within the task name
    if(regmatch):
        taskPoints = float(regmatch.group(1))
        totalPoints += taskPoints #Add the estimated points to the total
        if task['completed']:
            completedPoints += taskPoints

        tagExists = False
        for tag in task['tags']:
            if tag['name'] in tags:
                tags[tag['name']] += taskPoints
                tagExists = True
        if not tagExists:
            other += taskPoints
    else:
        unestimatedTasks += 1 #If the task did not have an estimation

    ##Actual effort
    regmatch = re.search(regexEffort, task['name'])
    if(regmatch):
        taskPoints = float(regmatch.group(1))
        effortPoints += taskPoints
        if(task['completed']):
            completedEffortPoints += taskPoints

#Calculate the percantages
completedPercentageStr = getPercentageStr(completedPoints, totalPoints)#Completed/Total
completedEffortPercentageStr = getPercentageStr(completedEffortPoints, effortPoints)#Effort/CompletedEffort
effortByEstimationPercentageStr = getPercentageStr(effortPoints, totalPoints)#Effort/TotalEstimation

#Print the result
print('\nEstimated total:', totalPoints)

#Points per tag
for key, value in tags.items():
    print(key, ':', value, getPercentageStr(value, totalPoints))
print('Other', ':', other, getPercentageStr(other, totalPoints))

#Completed points
print('\nCompleted:', completedPoints, completedPercentageStr)
print('Amount of unestimated tasks:', unestimatedTasks)

#Effort made
print('\nEffort made:', effortPoints, effortByEstimationPercentageStr, 'of total estimation')
print('Effort that turned into finished tasks:', completedEffortPoints, completedEffortPercentageStr)
