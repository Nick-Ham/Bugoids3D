extends KinematicBody

onready var mesh = $MeshInstance
onready var meshRotateAroundY = $MeshYContainer
onready var meshRotateAroundZ = $MeshYContainer/MeshZContainer
onready var detector = $Detector

var direction = Vector3()
var velocity
var boidRulesVector = Vector3()
var towardsTargetVector = Vector3()
var neighbors = []
onready var target = get_parent().transform.origin


var speed = 1
var inertiaPriority = 75
var cohesionMod = .5
var alignmentMod = .8
var avoidanceMod = 14
var towardsTargetMod = .1


func _ready():
	direction.x = (Globals.rng.randi()%100 - 50)/100.0
	direction.z = (Globals.rng.randi()%100 - 50)/100.0
	direction.y = (Globals.rng.randi()%100 - 50)/100.0

func _physics_process(delta):
	
	process_boid_rules()
	process_towards_target()
	process_movement(delta)
	process_mesh()

func process_boid_rules():
	boidRulesVector = Vector3()
	boidRulesVector = find_cohesion() + find_alignment() + find_avoidance()

func find_cohesion():
	var newCohesion = Vector3()
	
	if !neighbors.empty():
		for each in neighbors:
			newCohesion += each.global_transform.origin
		newCohesion /= neighbors.size()
		newCohesion = newCohesion - global_transform.origin
	
	return newCohesion * cohesionMod

func find_alignment():
	var newAlignment = Vector3()
	
	if !neighbors.empty():
		for each in neighbors:
			newAlignment = each.direction
		newAlignment = newAlignment.normalized()
	
	return newAlignment * alignmentMod

func find_avoidance():
	var newAvoidance = Vector3()
	var relativeDistanceMod = 0
	
	if !neighbors.empty():
		var closestNeighbor = neighbors[0]
		var minDistance = (closestNeighbor.global_transform.origin - global_transform.origin).length()
		for each in neighbors:
			var newDist = (each.global_transform.origin - global_transform.origin).length()
			if newDist < minDistance:
				closestNeighbor = each
		
		newAvoidance = closestNeighbor.global_transform.origin - global_transform.origin # direction towards neighbor
		newAvoidance *= -1
		relativeDistanceMod = 1 / newAvoidance.length()
	
	return newAvoidance * avoidanceMod * relativeDistanceMod

func process_towards_target():
	var towardsTarget = Vector3()
	var relativeDistanceMod = 0
	
	towardsTarget = target - global_transform.origin
	
	towardsTargetVector = towardsTarget

func process_movement(delta):
	direction += (boidRulesVector + (towardsTargetVector * towardsTargetMod))/ inertiaPriority
	direction = direction.normalized()
	velocity = direction * speed
	velocity = move_and_collide(velocity)


func process_mesh():
	meshRotateAroundY.rotation.y = atan2(direction.z, direction.x) * -1
	meshRotateAroundZ.rotation.z = atan2(direction.y, Vector2(direction.z,direction.x).length())


func _on_Detector_body_entered(body):
	if !body==self:
		if neighbors.size() < 10:
			neighbors.append(body)


func _on_Detector_body_exited(body):
	neighbors.erase(body)
