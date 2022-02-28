import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Checkpoints.Checkpoint;
import Vino.Checkpoints.Statics.CheckpointStatics;
import Cake.LevelSpecific.Clockwork.Actors.Misc.ClockworkGenericRootComponent;

class AClockworkGenericTimeActor : AHazeActor 
{
	UPROPERTY(DefaultComponent, RootComponent)
	UClockworkTimelineMovingObjectRootComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTimeControlActorComponent TimeComp;

	UPROPERTY()
	bool bShouldTimeScrubRotation;
	default bShouldTimeScrubRotation = false;

	UPROPERTY()
	bool bShouldTimeScrubLocation;
	default bShouldTimeScrubLocation = false;

	UPROPERTY()
	bool bShouldTimeScrubScale;
	default bShouldTimeScrubScale = false;

	UPROPERTY()
	bool bUseCurve;
	default bUseCurve = false;

	UPROPERTY()
	UCurveFloat Curve;

	FActorImpactedDelegate PlayerLanded;

	UPROPERTY()
	ACheckpoint Checkpoint;

	UPROPERTY()
	AActor AttachActor;

	UPROPERTY()
	FRotator TargetRotation;

	UPROPERTY()
	FRotator StartingRotation;

	UPROPERTY(meta = (MakeEditWidget))
	FVector TargetLocation;

	FVector StartingLocation;

	UPROPERTY()
	FVector TargetScale;

	FVector StartingScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeComp.TimeIsChangingEvent.AddUFunction(this, n"TimeChange");

		MeshRoot.SetRelativeRotation(StartingRotation);
		StartingLocation = MeshRoot.RelativeLocation;
		StartingScale = MeshRoot.RelativeScale3D;

		if(Checkpoint != nullptr)
		{
			Checkpoint.AttachToComponent(MeshRoot, n"", EAttachmentRule::KeepWorld);
			PlayerLanded.BindUFunction(this, n"ActivateCheckpoint");
			BindOnDownImpacted(this, PlayerLanded);
		}
		if(AttachActor != nullptr)
		{
			AttachActor.AttachToComponent(MeshRoot, n"", EAttachmentRule::KeepWorld);
		}
		TimeChange(TimeComp.PointInTime);
	}

	UFUNCTION()
	void ActivateCheckpoint(AHazeActor ImpactingActor, FHitResult Hit)
	{
		if(ImpactingActor != Game::GetMay())
			return;

		if (Hit.GetComponent().Name != n"Mesh" && Checkpoint != nullptr)
			{
				PlayerLanded.Clear();
				DisableAllCheckpointsForPlayer(Game::GetMay());
				Checkpoint.EnableForPlayer(Game::GetMay());
			}
	}

	UFUNCTION()
	void TimeChange(float CurrentPointInTime)
	{
		float PointInTimeToUse = CurrentPointInTime;
		if(bUseCurve)
			PointInTimeToUse = Curve.GetFloatValue(CurrentPointInTime);

		if (bShouldTimeScrubLocation)
			MeshRoot.SetRelativeLocation(FMath::VLerp(StartingLocation, TargetLocation, FVector(PointInTimeToUse, PointInTimeToUse, PointInTimeToUse)));

		if (bShouldTimeScrubRotation)
		{
			float NewRollValue = FMath::Lerp(StartingRotation.Roll, TargetRotation.Roll, PointInTimeToUse);
			float NewPitchValue = FMath::Lerp(StartingRotation.Pitch, TargetRotation.Pitch, PointInTimeToUse);
			float NewYawValue = FMath::Lerp(StartingRotation.Yaw, TargetRotation.Yaw, PointInTimeToUse);

			FRotator NewRot = FRotator(NewPitchValue, NewYawValue, NewRollValue);

			MeshRoot.SetRelativeRotation(NewRot);
		}

		if (bShouldTimeScrubScale)
			MeshRoot.SetRelativeScale3D(FMath::VLerp(StartingScale, TargetScale, FVector(PointInTimeToUse, PointInTimeToUse, PointInTimeToUse)));	
	}
}