import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.MagneticWheelActor;
import Peanuts.Audio.AudioStatics;

enum EMagneticWheelRotationalAxis
{
	Pitch,
	Yaw,
	Roll
};

class AmagneticWheelActorFollower : AHazeActor
{
	UPROPERTY()
	EMagneticWheelRotationalAxis RotationAxis = EMagneticWheelRotationalAxis::Pitch;

	UPROPERTY()
	bool bInvertRotation = false;

	UPROPERTY()
	AMagneticWheelActor WheelActor;

	UPROPERTY()
	float VelocityMultiplier = 0.75f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UFUNCTION(BlueprintEvent)
	void BP_OnStopRotate()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartRotate()
	{}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (WheelActor == nullptr)
		{
			SetActorTickEnabled(false);

		}

		if (bInvertRotation)
		{
			VelocityMultiplier *= -1;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (RotationAxis == EMagneticWheelRotationalAxis::Pitch)
		{
			AddActorLocalRotation(FRotator(0.f, WheelActor.CurrentVelocity * VelocityMultiplier *  DeltaTime , 0.f));
		}

		else if (RotationAxis == EMagneticWheelRotationalAxis::Roll)
		{
			AddActorLocalRotation(FRotator(WheelActor.CurrentVelocity * VelocityMultiplier *  DeltaTime, 0, 0));
		}

		else
		{
			AddActorLocalRotation(FRotator(0.f, 0.f , WheelActor.CurrentVelocity * VelocityMultiplier *  DeltaTime));
		}

		HazeAkComp.SetRTPCValue("Rtpc_SnowGlobe_Town_MagneticWheel_Velocity", WheelActor.CurrentVelocity);

		if (WheelActor.CurrentVelocity == 0)
		{
			BP_OnStopRotate();
		}

		else
		{
			BP_OnStartRotate();
		}

	}
}