import Vino.Movement.Swinging.SwingPoint;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonSpinnerRope;

class AHopscotchDungeonSwingNodeSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPoseableMeshComponent PullMyFingerMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent InvisibleMesh;
	default InvisibleMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent Impacts;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartSpinningAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSpinningAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RopePulledAudioEvent;

	UPROPERTY()
	AHopscotchDungeonSpinnerRope ConnectedSpinnerRope;

	UPROPERTY()
	ASwingPoint SwingPointToAttach01;

	float YawLastTick = 0.f;
	float CurrentRotationSpeed = 0.f;
	bool bShouldPlayAudio = false;

	bool bCurrentlyFarting = false;
	bool bHasPostedFarting = false;
	bool bPlayerAttachedToRope = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingPointToAttach01.AttachToComponent(MeshRoot, n"", EAttachmentRule::KeepWorld);
		ConnectedSpinnerRope.OnRopeMoving.AddUFunction(this, n"OnRopeMoving");
		ConnectedSpinnerRope.OnRopeAttach.AddUFunction(this, n"OnRopeAttach");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldPlayAudio && FMath::Abs(CurrentRotationSpeed) > 0.05f)
		{
			bShouldPlayAudio = true;
			HazeAkComp.HazePostEvent(StartSpinningAudioEvent);
		} else if (bShouldPlayAudio && FMath::Abs(CurrentRotationSpeed) < 0.05f)
		{
			bShouldPlayAudio = false;
			HazeAkComp.HazePostEvent(StopSpinningAudioEvent);
		}

		CurrentRotationSpeed = (YawLastTick - MeshRoot.RelativeRotation.Yaw) / DeltaTime;
		YawLastTick = MeshRoot.RelativeRotation.Yaw;

		// -1 going counter clockwise and 1 on clockwise
		CurrentRotationSpeed = FMath::GetMappedRangeValueClamped(FVector2D(-80.f, 80.f), FVector2D(1.f, -1.f), CurrentRotationSpeed);
		HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_Dungeon_SwingNodeSpinner_RotationSpeed", CurrentRotationSpeed);
	}

	UFUNCTION()
	void OnRopeMoving(float MoveValue)
	{
		FRotator Rot;
		Rot = FRotator(MeshRoot.RelativeRotation.Pitch, FMath::GetMappedRangeValueClamped(FVector2D(0.f, 300.f), FVector2D(90.f, 270.f), MoveValue), MeshRoot.RelativeRotation.Roll);
		MeshRoot.SetRelativeRotation(Rot);	

		float PumpHeight = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 300.f), FVector2D(0.f, 400.f), MoveValue);
		PullMyFingerMesh.SetBoneLocationByName(n"Pump", FVector(0.f, 0.f, PumpHeight), EBoneSpaces::ComponentSpace);

		float HeadYaw = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 300.f), FVector2D(0.f, 180.f), MoveValue);
		PullMyFingerMesh.SetBoneRotationByName(n"Head", FRotator(0.f, HeadYaw, 0.f), EBoneSpaces::ComponentSpace);

		if (MoveValue >= 250.f && bCurrentlyFarting && bPlayerAttachedToRope)
		{
			bCurrentlyFarting = false;
		} 
		else if (MoveValue < 250.f && !bCurrentlyFarting && bPlayerAttachedToRope) 
		{
			bCurrentlyFarting = true;
		}
		else if (!bPlayerAttachedToRope)
		{
			bCurrentlyFarting = false;
		}

		if  (bCurrentlyFarting && !bHasPostedFarting)
		{
			bHasPostedFarting = true;
			OnFart();
		}
		else if (!bCurrentlyFarting && bHasPostedFarting)
		{
			bHasPostedFarting = false;
			OnNotFart();
		}
	}

	UFUNCTION()
	void OnRopeAttach(bool bAttached)
	{
		bPlayerAttachedToRope = bAttached;
		if(bAttached)
		{
			HazeAkComp.HazePostEvent(RopePulledAudioEvent);
		}
		
	}

	UFUNCTION(BlueprintEvent)
	void OnFart()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void OnNotFart()
	{

	}
}