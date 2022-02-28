import Cake.LevelSpecific.SnowGlobe.Magnetic.CounterWeight.CounterWeightActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.MagneticWheelActor;
import Peanuts.Spline.SplineComponent;

enum ECounterWeightRotationalAxis
{
	Pitch,
	Yaw,
	Roll
};

class ACounterWeightRotationalFollower : AHazeActor
{
	UPROPERTY()
	ACounterWeightActor ActorToFollow;

	UPROPERTY()
	AMagneticWheelActor WheelToFollow; 

	UPROPERTY()
	float SpeedMultiplier = 1;

	float RotationalVelocity;

	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	ECounterWeightRotationalAxis RotationalAxis;

	FRotator OriginalRelativeRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalRelativeRotation = Mesh.RelativeRotation;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetProgress(DeltaTime);
	}

	UFUNCTION()
	void SetProgress(float DeltaTime)
	{
		if(ActorToFollow != nullptr)
			RotationalVelocity = ActorToFollow.CounterWeightVelocity;
		else if(WheelToFollow != nullptr)
			RotationalVelocity = WheelToFollow.CurrentVelocity;
		else
			return;
		
		FRotator Rotation;
		if (RotationalAxis == ECounterWeightRotationalAxis::Pitch)
		{
			Rotation.Pitch = RotationalVelocity * SpeedMultiplier;
		}

		else if (RotationalAxis == ECounterWeightRotationalAxis::Yaw)
		{
			Rotation.Yaw = RotationalVelocity * SpeedMultiplier;
		}

		else
		{
			Rotation.Roll = RotationalVelocity * SpeedMultiplier;
		}
		Mesh.AddLocalRotation(Rotation * DeltaTime);
	}
}