import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Hopscotch.FidgetspinnerActor;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.Hopscotch.AnimNotify_FidgetSpinnerAttachElevator;
import Peanuts.Audio.AudioStatics;
import void ActivateHopscotchElevator(AHazePlayerCharacter, AHopscotchElevator, USceneComponent) from "Cake.LevelSpecific.Hopscotch.HopscotchElevatorComponent";
import void DeactivateHopscotchElevator(AHazePlayerCharacter) from "Cake.LevelSpecific.Hopscotch.HopscotchElevatorComponent";

struct FFidgetSpinnerData
{
    bool bHasFidgetSpinner;
	bool bIsYellow;
}

event void FHopscotchElevatorSignature(bool bCodyOnLeft);

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHopscotchElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = LeftFidgetSpinner)
	UHazeAkComponent HazeAkCompLeftFidget;

	UPROPERTY(DefaultComponent, Attach = RightFidgetSpinner)
	UHazeAkComponent HazeAkCompRightFidget;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeftFidgetAttachAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RightFidgetAttachAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeftFidgetStopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RightFidgetStopAudioEvent;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkCompElevator;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElevatorStartMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElevatorStopMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElevatorFinishedAudioEvent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent ElevatorCam;
	default ElevatorCam.RelativeLocation = FVector(0.f, 1100.f, 650.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractionCompLeft;
	default InteractionCompLeft.RelativeLocation = FVector(-740.f, 0.f, 10.f);
	default InteractionCompLeft.RelativeRotation = FRotator(0.f, -90.f, 0.f);
	default InteractionCompLeft.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 2.f);
	default InteractionCompLeft.ActionShapeTransform.Location = FVector(0.f, 0.f, -190.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractionCompRight;
	default InteractionCompRight.RelativeLocation = FVector(740.f, 0.f, 10.f);
	default InteractionCompRight.RelativeRotation = FRotator(0.f, -90.f, 0.f);
	default InteractionCompRight.ActionShapeTransform.Location = FVector(0.f, 0.f, -190.f);
	default InteractionCompRight.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 2.f);

	UPROPERTY(DefaultComponent, Attach = InteractionCompLeft)
	USkeletalMeshComponent PreviewMesh;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent LeftFidgetRoot;
	default LeftFidgetRoot.RelativeLocation = FVector(-710.f, 0.f, 165.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent RightFidgetRoot;
	default RightFidgetRoot.RelativeLocation = FVector(705.f, 0.f, 165.f);

	UPROPERTY(DefaultComponent, Attach = LeftFidgetRoot)
	UStaticMeshComponent LeftFidgetSpinner;
	default LeftFidgetSpinner.RelativeRotation = FRotator(-90.f, 0.f, 0.f);
	default LeftFidgetSpinner.bHiddenInGame = true;
	default LeftFidgetSpinner.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = LeftFidgetSpinner)
	UStaticMeshComponent LeftFidgetSpinnerBase;
	default LeftFidgetSpinnerBase.RelativeRotation = FRotator(0.f, 0.f, 0.f);
	default LeftFidgetSpinnerBase.bHiddenInGame = true;
	default LeftFidgetSpinnerBase.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = RightFidgetRoot)
	UStaticMeshComponent RightFidgetSpinner;
	default RightFidgetSpinner.RelativeRotation = FRotator(90.f, 0.f, 0.f);
	default RightFidgetSpinner.bHiddenInGame = true;
	default RightFidgetSpinner.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = RightFidgetSpinner)
	UStaticMeshComponent RightFidgetSpinnerBase;
	default RightFidgetSpinnerBase.RelativeRotation = FRotator(0.f, 0.f, 0.f);
	default RightFidgetSpinnerBase.bHiddenInGame = true;
	default RightFidgetSpinnerBase.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent LeftAttachComponent;
	default LeftAttachComponent.RelativeLocation = FVector(-740.f, 0.f, 10.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent RightAttachComponent;
	default RightAttachComponent.RelativeLocation = FVector(740.f, 0.f, 10.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent LeftButtonMashCollision;
	default LeftButtonMashCollision.RelativeLocation = FVector(-710.f, 0.f, 100.f);
	default LeftButtonMashCollision.BoxExtent = FVector(100.f, 85.f, 130.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent RightButtonMashCollision;
	default RightButtonMashCollision.RelativeLocation = FVector(710.f, 0.f, 100.f);
	default RightButtonMashCollision.BoxExtent = FVector(100.f, 85.f, 130.f);

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent ZSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftProgressSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent RightProgressSync;

	UPROPERTY()
	FHazeTimeLike MoveCamBeforeCutsceneTimeline;
	default MoveCamBeforeCutsceneTimeline.Duration = 0.5f;

	UPROPERTY()
	FHopscotchElevatorSignature StartSequenceEvent;

	UPROPERTY()
	UStaticMesh BlueFidgetArmsMesh;

	UPROPERTY()
	UStaticMesh BlueFidgetBaseMesh;

	UPROPERTY()
	UStaticMesh YellowFidgetArmsMesh;

	UPROPERTY()
	UStaticMesh YellowFidgetBaseMesh;

	AFidgetSpinnerActor FidgetSpinnerToRemove;
	
	UPROPERTY()
	TSubclassOf<UHazeCapability> FidgetSpinnerCapability;

	UPROPERTY()
	TSubclassOf<UHazeCapability> FidgetSpinnerAirControlCapability;

	UPROPERTY()
	TSubclassOf<UHazeCapability> BananaBounceCapability;

	UButtonMashProgressHandle LeftButtonMashHandle;
	UButtonMashProgressHandle RightButtonMashHandle;

	AHazePlayerCharacter PlayerOccupyingLeftHandle;
	AHazePlayerCharacter PlayerOccupyingRightHandle;

	float ButtonMashLeftProgression;
	float LeftProgression;

	float SyncTimer = 0.f;
	float TargetZLocation;

	float LeftTargetProgress;
	float RightTargetProgress;

	float CurrentLeftSpinRate;
	float CurrentRightSpinRate;

	bool bLeftFidgetAttached;
	bool bRightFidgetAttached;

	bool bHasActivatedCam = false;

	bool bCodyOnLeft;

	float StartingZLoc;

	bool bElevatorIsMoving = false;

	UPROPERTY()
	float LeftGoingBackForce;
	default LeftGoingBackForce = 1.f;

	UPROPERTY()
	float LeftProgressionForce;
	default LeftProgressionForce = 0.3f;

	float RightProgression;

	UPROPERTY()
	float RightGoingBackForce;
	default RightGoingBackForce = 1.f;

	UPROPERTY()
	float RightProgressionForce;
	default RightProgressionForce = 0.3f;

	bool bElevatorFinished = false;

	UPROPERTY()
	TSubclassOf<UHazeCapability> ElevatorCapability;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionCompLeft.OnActivated.AddUFunction(this, n"LeftFidgetActivated");
		InteractionCompRight.OnActivated.AddUFunction(this, n"RightFidgetActivated");

		LeftButtonMashCollision.OnComponentBeginOverlap.AddUFunction(this, n"MashCollisionBeginOverlap");
		RightButtonMashCollision.OnComponentBeginOverlap.AddUFunction(this, n"MashCollisionBeginOverlap");
		LeftButtonMashCollision.OnComponentEndOverlap.AddUFunction(this, n"MashCollisionEndOverlap");
		RightButtonMashCollision.OnComponentEndOverlap.AddUFunction(this, n"MashCollisionEndOverlap");

		MoveCamBeforeCutsceneTimeline.BindUpdate(this, n"MoveCamBeforeCutsceneTimelineUpdate");

		LeftProgressSync.OverrideControlSide(Game::GetMay());
		RightProgressSync.OverrideControlSide(Game::GetCody());

		StartingZLoc = GetActorLocation().Z;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayerOccupyingLeftHandle != nullptr && PlayerOccupyingRightHandle != nullptr && !bHasActivatedCam)
		{
			bHasActivatedCam = true;
			FHazeCameraBlendSettings Blend;
			Game::GetMay().ActivateCamera(ElevatorCam, Blend, this);
			Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			ElevatorStarted();
		}
		
		if (!bElevatorFinished)
		{
			if (LeftButtonMashHandle != nullptr)
			{
				if (CurrentLeftSpinRate < LeftButtonMashHandle.Progress * -1000.f * DeltaTime && CurrentLeftSpinRate != 0.f)
				{
					CurrentLeftSpinRate += DeltaTime * 10.f;
				} else 
				{
					CurrentLeftSpinRate = LeftButtonMashHandle.Progress * -1000.f * DeltaTime;
				}
				
				if (PlayerOccupyingLeftHandle.HasControl())
				{
					PlayerOccupyingLeftHandle.SetCapabilityAttributeValue(n"LeftElevatorMashRate", LeftButtonMashHandle.MashRateControlSide);
					LeftProgression = FMath::Clamp(LeftProgression - (LeftGoingBackForce * ActorDeltaSeconds), 0.f, 1.f);
					LeftProgression = FMath::Clamp(LeftProgression + (LeftButtonMashHandle.MashRateControlSide * LeftProgressionForce * ActorDeltaSeconds), 0.f, 1.f);
					LeftButtonMashHandle.Progress = LeftProgression;	
				}

				else
				{
					LeftButtonMashHandle.Progress = LeftProgressSync.GetValue();
				}			
			} else 
			{
				if (CurrentLeftSpinRate < 0)
					CurrentLeftSpinRate += DeltaTime * 10.f;
			}
				
				LeftFidgetRoot.AddRelativeRotation(FRotator(0.f, 0.f, CurrentLeftSpinRate));

			if (RightButtonMashHandle != nullptr)
			{

				if (CurrentRightSpinRate < RightButtonMashHandle.Progress * -1000.f * DeltaTime && CurrentRightSpinRate != 0.f)
				{
					CurrentRightSpinRate += DeltaTime * 10.f;
				} else 
				{
					CurrentRightSpinRate = RightButtonMashHandle.Progress * -1000.f * DeltaTime;
				}


				if (PlayerOccupyingRightHandle.HasControl())
				{
					PlayerOccupyingRightHandle.SetCapabilityAttributeValue(n"RightElevatorMashRate", RightButtonMashHandle.MashRateControlSide);
					RightProgression = FMath::Clamp(RightProgression - (RightGoingBackForce * ActorDeltaSeconds), 0.f, 1.f);
					RightProgression = FMath::Clamp(RightProgression + (RightButtonMashHandle.MashRateControlSide * RightProgressionForce * ActorDeltaSeconds), 0.f, 1.f);
					RightButtonMashHandle.Progress = RightProgression;
				}

				else
				{
					RightButtonMashHandle.Progress = RightProgressSync.GetValue();
				}
			}	else 
			{
				if (CurrentRightSpinRate < 0)
					CurrentRightSpinRate += DeltaTime * 10.f;
			}
			
				RightFidgetRoot.AddRelativeRotation(FRotator(0.f, 0.f, CurrentRightSpinRate));


			if (LeftButtonMashHandle != nullptr && RightButtonMashHandle != nullptr && HasControl())
			{
				if (RightButtonMashHandle.Progress > 0.5f && LeftButtonMashHandle.Progress > 0.5f)
				{
					FVector CurrentOffset = FVector(0.f, 0.f, 200.f * RightButtonMashHandle.Progress * ActorDeltaSeconds);	
					AddActorLocalOffset(CurrentOffset);	
				}

				if (GetActorLocation().Z - StartingZLoc >= 950.f)
				{
					NetElevatorFinished();
				}
			}
					
			if (HasControl())
			{
				ZSync.Value = GetActorLocation().Z - StartingZLoc;
			}
			
			if (PlayerOccupyingLeftHandle != nullptr && PlayerOccupyingLeftHandle.HasControl())
			{ 
				LeftProgressSync.Value = LeftButtonMashHandle.Progress;
			}
			if (PlayerOccupyingRightHandle != nullptr && PlayerOccupyingRightHandle.HasControl())
			{ 
				RightProgressSync.Value = RightButtonMashHandle.Progress;
			}
			

			if (!HasControl())
			{
				SetActorLocation(FMath::VInterpConstantTo(GetActorLocation(), FVector(GetActorLocation().X, GetActorLocation().Y, ZSync.GetValue() + StartingZLoc), DeltaTime, 200.f));
			}

			HazeAkCompLeftFidget.SetRTPCValue("Rtpc_Vehicles_FidgetSpinner_Elevator_RotationSpeed", LeftProgressSync.Value);
			HazeAkCompRightFidget.SetRTPCValue("Rtpc_Vehicles_FidgetSpinner_Elevator_RotationSpeed", RightProgressSync.Value);
		}

		if(LeftProgressSync.Value > 0.5f && RightProgressSync.Value > 0.5f && !bElevatorIsMoving)
		{
			HazeAkCompElevator.HazePostEvent(ElevatorStartMoveAudioEvent);
			bElevatorIsMoving = true;
		}
		else if(LeftProgressSync.Value < 0.5f && RightProgressSync.Value < 0.5f && bElevatorIsMoving)
		{
			HazeAkCompElevator.HazePostEvent(ElevatorStopMoveAudioEvent);
			bElevatorIsMoving = false;
		}
	}

	UFUNCTION()
	void MoveCamBeforeCutsceneTimelineUpdate(float CurrentValue)
	{
		ElevatorCam.SetRelativeLocation(FMath::Lerp(FVector(0.f, 1100.f, 650.f), FVector(0.f, 1100.f, 1650.f), CurrentValue));
	}

	UFUNCTION(BlueprintEvent)
	void ElevatorStarted()
	{

	}

	UFUNCTION(NetFunction)
	void NetElevatorFinished()
	{
		for(auto Player : Game::GetPlayers())
			DeactivateHopscotchElevator(Player);
		
		StartSequenceEvent.Broadcast(bCodyOnLeft);
		bElevatorFinished = true;
		HazeAkCompElevator.HazePostEvent(ElevatorFinishedAudioEvent);
		HazeAkCompLeftFidget.HazePostEvent(LeftFidgetStopAudioEvent);
		HazeAkCompLeftFidget.HazePostEvent(RightFidgetStopAudioEvent);

		LeftFidgetSpinner.SetHiddenInGame(true);
		LeftFidgetSpinnerBase.SetHiddenInGame(true);
		RightFidgetSpinner.SetHiddenInGame(true);
		RightFidgetSpinnerBase.SetHiddenInGame(true);
	}

	UFUNCTION()
    void MashCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			UBoxComponent Box = Cast<UBoxComponent>(OverlappedComponent);

			if (Box == LeftButtonMashCollision && bLeftFidgetAttached && LeftButtonMashHandle == nullptr)
			{
				LeftButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, LeftAttachComponent, n"", FVector::ZeroVector);
				PlayerOccupyingLeftHandle = Player;
				
				if (Player == Game::GetCody())
					bCodyOnLeft = true;

				else
					bCodyOnLeft = false;
			}

			if (Box == RightButtonMashCollision && bRightFidgetAttached && RightButtonMashHandle == nullptr)
			{
				RightButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, RightAttachComponent, n"", FVector::ZeroVector);
				PlayerOccupyingRightHandle = Player;
			}
			
		}
    }

	UFUNCTION()
    void MashCollisionEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		UBoxComponent Box = Cast<UBoxComponent>(OverlappedComponent);

		if (Box == LeftButtonMashCollision && bLeftFidgetAttached && Cast<AHazePlayerCharacter>(OtherActor) == PlayerOccupyingLeftHandle)
		{
			RemoveButtonMashFromPlayer(Box);
			LeftButtonMashHandle = nullptr;
			LeftProgression = 0.f;
			PlayerOccupyingLeftHandle = nullptr;
		}		

		if (Box == RightButtonMashCollision && bRightFidgetAttached && Cast<AHazePlayerCharacter>(OtherActor) == PlayerOccupyingRightHandle)
		{
			RemoveButtonMashFromPlayer(Box);
			RightButtonMashHandle = nullptr;
			RightProgression = 0.f;
			PlayerOccupyingRightHandle = nullptr;
		}		
    }	

	UFUNCTION()
	void LeftFidgetActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		ActivateHopscotchElevator(Player, this, Comp);
		Player.AddCapability(ElevatorCapability);	
		Comp.DisableForPlayer(Game::GetMay(), n"ElevatorBeingUsed");
		HazeAudio::SetPlayerPanning(HazeAkCompLeftFidget, Player);
		HazeAkCompLeftFidget.HazePostEvent(LeftFidgetAttachAudioEvent);
	}

	UFUNCTION()
	void RightFidgetActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		ActivateHopscotchElevator(Player, this, Comp);
		Player.AddCapability(ElevatorCapability);
		Comp.DisableForPlayer(Game::GetCody(), n"ElevatorBeingUsed");
		HazeAudio::SetPlayerPanning(HazeAkCompRightFidget, Player);
		HazeAkCompRightFidget.HazePostEvent(RightFidgetAttachAudioEvent);
	}

	void SetSpinnerMesh(bool bIsYellow, bool bLeft)
	{
		UStaticMeshComponent BaseToSet = bLeft ? LeftFidgetSpinnerBase : RightFidgetSpinnerBase;
		UStaticMeshComponent ArmsToSet = bLeft ? LeftFidgetSpinner : RightFidgetSpinner;
		UStaticMesh BaseMeshToSet = bIsYellow ? YellowFidgetBaseMesh : BlueFidgetBaseMesh;
		UStaticMesh ArmMeshToSet = bIsYellow ? YellowFidgetArmsMesh : BlueFidgetArmsMesh;

		BaseToSet.SetStaticMesh(BaseMeshToSet);
		ArmsToSet.SetStaticMesh(ArmMeshToSet);
	}

	void RemoveButtonMashFromPlayer(UBoxComponent BoxComp)
	{
		if (BoxComp == LeftButtonMashCollision && LeftButtonMashHandle != nullptr)
			StopButtonMash(LeftButtonMashHandle);

		if (BoxComp == RightButtonMashCollision && RightButtonMashHandle != nullptr)
			StopButtonMash(RightButtonMashHandle);
	}

	FFidgetSpinnerData PlayerHasFidgetSpinnerAttached(AHazePlayerCharacter Player)
	{
		FFidgetSpinnerData SpinnerData;
		TArray<AActor> ActorArray;
		bool bHasFidget = false;
		Player.GetAttachedActors(ActorArray);

		for(AActor Actor : ActorArray)
		{
			AFidgetSpinnerActor FidgetActor = Cast<AFidgetSpinnerActor>(Actor);
			if (FidgetActor != nullptr)
			{
				SpinnerData.bHasFidgetSpinner = true;
				SpinnerData.bIsYellow = FidgetActor.bYellowFidgetspinner;
				FidgetActor.DestroyActor();
				Player.RemoveCapability(FidgetSpinnerCapability);
				Player.RemoveCapability(FidgetSpinnerAirControlCapability);
				Player.RemoveCapability(BananaBounceCapability);
			}
		}

		return SpinnerData;
	}

	void AttachLeftFidgetSpinner()
	{
		FFidgetSpinnerData SpinnerData = PlayerHasFidgetSpinnerAttached(Game::GetMay());

		if (SpinnerData.bHasFidgetSpinner && !bLeftFidgetAttached)
		{
			bLeftFidgetAttached = true;
			LeftFidgetSpinner.SetHiddenInGame(false);
			LeftFidgetSpinnerBase.SetHiddenInGame(false);
			InteractionCompLeft.Disable(n"FidgetSpinnerPlaced");
			SetSpinnerMesh(SpinnerData.bIsYellow, true);
		}
	}

	void StartLeftButtonMash()
	{
		LeftButtonMashHandle = StartButtonMashProgressAttachToComponent(Game::GetMay(), LeftAttachComponent, n"", FVector::ZeroVector);
		PlayerOccupyingLeftHandle = Game::GetMay();
	}

	void AttachRightFidgetSpinner()
	{
		FFidgetSpinnerData SpinnerData = PlayerHasFidgetSpinnerAttached(Game::GetCody());

		if (SpinnerData.bHasFidgetSpinner && !bRightFidgetAttached)
		{
			bRightFidgetAttached = true;
			RightFidgetSpinner.SetHiddenInGame(false);
			RightFidgetSpinnerBase.SetHiddenInGame(false);
			InteractionCompRight.Disable(n"FidgetSpinnerPlaced");
			SetSpinnerMesh(SpinnerData.bIsYellow, false);
		}
	}

	void StartRightButtonMash()
	{
		RightButtonMashHandle = StartButtonMashProgressAttachToComponent(Game::GetCody(), RightAttachComponent, n"", FVector::ZeroVector);
		PlayerOccupyingRightHandle = Game::GetCody();
	}
}