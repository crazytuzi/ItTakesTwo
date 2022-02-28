import Vino.Trajectory.TrajectoryStatics;

enum ETrajectoryMethod
{
	Prediction,
	Calculation
}

UCLASS(HideCategories = "Physics Collision Rendering Cooking Tags LOD Activation AssetUserData")
class UTrajectoryComponent : USceneComponent
{
	// Target position to hit of calculated trajectory
	UPROPERTY(Category = "Trajectory|Calculation", meta = (MakeEditWidget = true))
	FVector LocalTargetPosition;

	// Height of the calculated trajectory
	UPROPERTY(Category = "Trajectory|Calculation", meta = (MakeEditWidget = true))
	FVector LocalTargetHeight;

	// Determines if the velocity given is in world space, or relative to the component transform
	UPROPERTY(Category = "Trajectory|Prediction")
	bool bWorldSpace = true;

	// Velocity of the object to predict
	UPROPERTY(Category = "Trajectory|Prediction")
	FVector Velocity;

	// Gravity of the object in units/s
	UPROPERTY(Category = "Trajectory")
	float Gravity = 920.f;

	// Terminal falling speed of trajectory (-1 means unlimited)
	UPROPERTY(Category = "Trajectory")
	float TerminalSpeed = -1.f;

	// Method to predict and draw trajectory
	//  Prediction: Will take input velocity and draw the trajectory achieved with that initial velocity
	//  Calculation: Will take input target position and height, and calculate the velocity to teach that position, then draw that trajectory
	UPROPERTY(Category = "Trajectory")
	ETrajectoryMethod TrajectoryMethod;

	// Resolution of the trajectory (higher means more points)
	UPROPERTY(Category = "Trajectory")
	float VisualizeResolution = 1.f;

	// Length of the trajectory prediction
	UPROPERTY(Category = "Trajectory")
	float VisualizeLength = 2000.f;

	UFUNCTION(BlueprintCallable)
	void SetTargetWorldLocation(FVector WorldLoc) property
	{
		LocalTargetPosition = GetWorldTransform().InverseTransformPosition(WorldLoc);
	}

	UFUNCTION(BlueprintPure)
	FVector GetCalculatedVelocity(FVector UpVec = FVector::UpVector) property
	{
		FVector WorldPosition = GetWorldTransform().TransformPosition(LocalTargetPosition);

		return CalculateVelocityForPathWithHeight(GetWorldLocation(), WorldPosition, Gravity, LocalTargetHeight.Z, TerminalSpeed, UpVec);
	}
}