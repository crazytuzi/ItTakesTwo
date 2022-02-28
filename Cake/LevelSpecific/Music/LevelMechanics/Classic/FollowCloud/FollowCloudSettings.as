UCLASS(Meta = (ComposeSettingsOnto = "UFollowCloudSettings"))
class UFollowCloudSettings : UHazeComposableSettings
{
	// Cloud air friction
	UPROPERTY()
	float Drag = 0.8f;

	// How hard a powerful song will push away cloud (single impulse)
	UPROPERTY()
	float ImpulseValue = 2300;
	
	// How hard the song of life will pull on cloud (continuous impulse)
	UPROPERTY()
	float SongOfLifeForce = 20.f;

	// How hard the cloud is pulled towards return destination (continuous impulse)
	UPROPERTY()
	float ReturnForce = 40.f;

	// Max speed allowed when pulled towards return destination
	UPROPERTY()
	float ReturnMaxSpeed = 1000.f;

	// When returning from below plane, we accelerate this much more upwards than straight to random destination
	UPROPERTY()
	float ReturnFromBelowPlaneUpwardsBias = 0.5f;

	// How deep within the bounds will we look for a return destination when we're out of bounds?
	UPROPERTY()
	float ReturnWithinBoundsDepth = 35.f;

	// For how long will we continue towards destination after returning within bounds?
	UPROPERTY()
	float ReturnWithinBoundsDuration = 0.2f;

	// How far outside collision capsule we will be able to push away players
	UPROPERTY()
	float PushPlayersCollisionPadding = 400.f;

	// For how many seconds players lose input when hit by cloud
	UPROPERTY()
	float PushPlayersDuration = 0.5f;

	// How hard players are pushed when hitting the cloud
	UPROPERTY()
	float PushPlayersForce = 3000.f;

	// Gravity factor while push is active
	UPROPERTY()
	float PushPlayersGravity = 0.2f;
}