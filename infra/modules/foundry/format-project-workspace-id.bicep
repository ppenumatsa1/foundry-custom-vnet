@description('Project workspace internal ID')
param projectWorkspaceId string

var workspaceParts = split(projectWorkspaceId, '/')
var projectWorkspaceIdGuid = last(workspaceParts)

output projectWorkspaceIdGuid string = projectWorkspaceIdGuid
