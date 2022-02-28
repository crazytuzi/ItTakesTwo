
UCLASS(meta=(ComposeSettingsOnto = "UBeanstalkSettings"))
class UBeanstalkSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Movement)
	float Acceleration = 20.0f;

	UPROPERTY(Category = Movement)
	float MovementSpeedMaximum = 1000.0f;

	// This affects how far teh beanstalk appears and moves up from soil.
	UPROPERTY(Category = Movement)
	float InitialVelocity = 500.0f;

	UPROPERTY(Category = Movement)
	float Deceleration = 1.5f;

	UPROPERTY(Category = Movement)
	float SpringSize = 300.0f;

	UPROPERTY(Category = LeafSpawning)
	float LeafPairDistance = 500.0f;

	UPROPERTY(Category = LeafSpawning)
	float LeafPairsDistanceMinimum = 750;

	UPROPERTY(Category = LeafSpawning)
	float RemoveLeafPairDistance = 250;

	UPROPERTY(Category = Camera)
	FRotator FollowOffset = FRotator(-20, 0, 0);

	// Set different camera settisettings when reversing. Keep same as FollowOffset otherwise. (Not used in TopView)
	UPROPERTY(Category = Camera)
	FRotator ReverseFollowOffset = FRotator(-20, -180, 0);

	// How long the beanstalk needs to reverse in order to flip the follow camera.
	UPROPERTY(Category = Camera)
	float ReverseInputDuration = 1.0f;

	UPROPERTY(Category = Deprecated, meta = (ClampMin = -180, ClampMax = 180))
	float TopViewCameraPitchOffset = 0;

	// This is the sphere for detecting how close the head is to possible blocking environment, determining when leafs will close.
	UPROPERTY(Category = Visual)
	float EnvironmentSphereRadius = 350.0f;

	// Offset from CollisionComponent to EnvironmentSphereRadius
	UPROPERTY(Category = Visual)
	float EnvironmentScanOffset = 0.0f;
}
