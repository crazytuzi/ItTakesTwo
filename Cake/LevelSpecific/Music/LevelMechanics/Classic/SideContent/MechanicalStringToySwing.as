import Vino.Movement.Swinging.SwingPoint;

class AMechanicalStringToySwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootCompMain;
	UPROPERTY(DefaultComponent, Attach = RootCompMain)
	USceneComponent RootCompMainTwoa;
	UPROPERTY(DefaultComponent, Attach = RootCompMainTwoa)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftArmSceneComp;
	UPROPERTY(DefaultComponent, Attach = LeftArmSceneComp)
	UStaticMeshComponent LeftArm;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightArmSceneComp;
	UPROPERTY(DefaultComponent, Attach = RightArmSceneComp)
	UStaticMeshComponent RightArm;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftLegSceneComp;
	UPROPERTY(DefaultComponent, Attach = LeftLegSceneComp)
	UStaticMeshComponent LeftLeg;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightLegSceneComp;
	UPROPERTY(DefaultComponent, Attach = RightLegSceneComp)
	UStaticMeshComponent RightLeg;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent StringMeshSceneComp;
	UPROPERTY(DefaultComponent, Attach = StringMeshSceneComp)
	UStaticMeshComponent StringMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 15000.f;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY()
	ASwingPoint SwingPoint;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMovementAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMovementAudioEvent;

	int PlayerInt;
	bool SoundPlaying = false;
	float DistanceFromTarget;

	//Variable to compute blendspace value
	UPROPERTY(BlueprintReadOnly)
	float DistanceFromCenter;

	//Variable to compute blendspace value
	UPROPERTY(BlueprintReadOnly)
	FVector ForwardVectorToTarget;

	//Bool to know if attached
	UPROPERTY(BlueprintReadOnly)
	bool HasEntered;

	//Bool to know if detached
	UPROPERTY(BlueprintReadOnly)
	bool HasExited;

	UPROPERTY()
	float LeftArmRotation = -65;
	UPROPERTY()
	float RightLegRotation = 40;
	UPROPERTY()
	float RightArmRotation = 65;
	UPROPERTY()
	float LeftLegRotation = -40;

	float TargetLeftLegRotation;
	float TargetLeftArmRotation;
	float TargetRightLegRotation;
	float TargetRightArmRotation;
	FHazeAcceleratedFloat AcceleratedFloatLeftArm;
	FHazeAcceleratedFloat AcceleratedFloatLeftLeg;
	FHazeAcceleratedFloat AcceleratedFloatRightArm;
	FHazeAcceleratedFloat AcceleratedFloatRightLeg;

	UPROPERTY()
	float SwingpointOffsetAttach = -480;
	UPROPERTY()
	float MeshRotationMultiplier = 2;
	
	UPROPERTY()
	float TargetLocationZ = -320;
	float SwingTargetLocationZ;
	FHazeAcceleratedFloat AcceleratedFloatSwing;
	FHazeAcceleratedRotator AcceleratedFloatSwingRotation;
	FRotator TargetSwingRotation;
	FRotator CurSwingRotation;
	AHazePlayerCharacter MainPlayer;

	FHazeAcceleratedFloat AcceleratedFloatMovementIntesity;
	float MovementIntensityLerpSpeed = 60;
	float TargetMovementIntensity = 0;
	float MovementIntensity = 0;
	bool bMovingUp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SwingPoint == nullptr)
			return; 
			
		SwingPoint.OnSwingPointAttached.AddUFunction(this, n"OnPlayerAttached");
		SwingPoint.OnSwingPointDetached.AddUFunction(this, n"OnPlayerDetached");
		SwingPoint.AttachToComponent(StringMesh, NAME_None , EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		SwingPoint.AddActorLocalOffset(FVector(0, 0, SwingpointOffsetAttach));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloatLeftArm.SpringTo(TargetLeftArmRotation - DistanceFromCenter * 30, 45, 0.4, DeltaSeconds);
		AcceleratedFloatLeftLeg.SpringTo(TargetLeftLegRotation - DistanceFromCenter * 30, 30, 0.4, DeltaSeconds);
		AcceleratedFloatRightArm.SpringTo(TargetRightArmRotation + DistanceFromCenter * 30, 45, 0.4, DeltaSeconds);
		AcceleratedFloatRightLeg.SpringTo(TargetRightLegRotation + DistanceFromCenter * 30, 30, 0.4, DeltaSeconds);

		AcceleratedFloatSwing.SpringTo(SwingTargetLocationZ + (DistanceFromCenter * 200) - 140, 25, 0.85, DeltaSeconds);
		AcceleratedFloatSwingRotation.SpringTo(TargetSwingRotation, 30, 0.9, DeltaSeconds);


		if(bMovingUp)
		{
			if(MovementIntensity >= TargetMovementIntensity)
			{
				if(FMath::IsNearlyEqual(MovementIntensity, 1.0f, 0.05f))
					TargetMovementIntensity = 0.3f;
				else if(FMath::IsNearlyEqual(MovementIntensity, 0.3f, 0.05f))
					TargetMovementIntensity = 0.6f;
				else if(FMath::IsNearlyEqual(MovementIntensity, 0.6f, 0.05f))
					TargetMovementIntensity = 0.3f;
			}
		}

		AcceleratedFloatMovementIntesity.SpringTo(TargetMovementIntensity, MovementIntensityLerpSpeed, 0.8f, DeltaSeconds);
		MovementIntensity = AcceleratedFloatMovementIntesity.Value;
		HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Music_Interactions_MechanicalStringToy_Movement", MovementIntensity);

		FRotator RelativeRotationLeftArm;
		RelativeRotationLeftArm.Roll = AcceleratedFloatLeftArm.Value;
		LeftArm.SetRelativeRotation(RelativeRotationLeftArm);

		FRotator RelativeRotationLeftLeg;
		RelativeRotationLeftLeg.Roll = AcceleratedFloatLeftLeg.Value;
		LeftLeg.SetRelativeRotation(RelativeRotationLeftLeg);

		FRotator RelativeRotationRightArm;
		RelativeRotationRightArm.Roll = AcceleratedFloatRightArm.Value;
		RightArm.SetRelativeRotation(RelativeRotationRightArm);

		FRotator RelativeRotationRightLeg;
		RelativeRotationRightLeg.Roll = AcceleratedFloatRightLeg.Value;
		RightLeg.SetRelativeRotation(RelativeRotationRightLeg);

		FVector RelativeLocationString;
		RelativeLocationString.Z = AcceleratedFloatSwing.Value;
		StringMesh.SetRelativeLocation(FVector(0, 0, RelativeLocationString.Z));

		FRotator RelativeRotationString;
		RelativeRotationString = AcceleratedFloatSwingRotation.Value;
		StringMesh.SetRelativeRotation(FRotator(RelativeRotationString.Pitch * (-ForwardVectorToTarget.X * 1), RelativeRotationString.Yaw * (-ForwardVectorToTarget.Y * 1), RelativeRotationString.Roll * (-ForwardVectorToTarget.Z * 1)));

		FRotator RelativeRotationMainMesh;
		RelativeRotationMainMesh = AcceleratedFloatSwingRotation.Value;
		RootCompMainTwoa.SetRelativeRotation(FRotator(RelativeRotationMainMesh.Pitch * (-ForwardVectorToTarget.X * MeshRotationMultiplier), RelativeRotationMainMesh.Yaw * (-ForwardVectorToTarget.Y * MeshRotationMultiplier), RelativeRotationMainMesh.Roll * (-ForwardVectorToTarget.Z * MeshRotationMultiplier)));

		if(MainPlayer != nullptr)
		{
			DistanceFromTarget = (Billboard.GetWorldLocation()  - MainPlayer.GetActorLocation()).Size();
			DistanceFromCenter = DistanceFromTarget/800;
			ForwardVectorToTarget = (Billboard.GetWorldLocation() - MainPlayer.GetActorLocation());
			ForwardVectorToTarget.Normalize();
			SwingTargetLocationZ = TargetLocationZ;
			//Make rotation local
			ForwardVectorToTarget = Billboard.GetWorldRotation().UnrotateVector(ForwardVectorToTarget);
			TargetSwingRotation = 1;
			
			//Print("PlayerInt   "+ PlayerInt);
			//Print("SoundPlaying   "+ SoundPlaying);
			//Print("MainPlayer  " + MainPlayer);
			//Print("DistanceFromTarget  " + DistanceFromTarget);
			//PrintToScreen("DistanceFromCenter  " + DistanceFromCenter);
			//PrintToScreen("ForwardVectorToTarget  " + ForwardVectorToTarget);
		}
		else
		{
			DistanceFromCenter = 0;
			TargetSwingRotation = 0;
		}
	}

	UFUNCTION()
	void OnPlayerAttached(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			NetAddPlayer(Player);
			//Set correct bool values
			HasEntered = true;
			HasExited = false;
		}
	}
	UFUNCTION()
	void OnPlayerDetached(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			NetRemovePlayer(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetAddPlayer(AHazePlayerCharacter Player)
	{
		PlayerInt ++;
		bMovingUp = true;
		MovementIntensityLerpSpeed = 60;
		CheckPlayers(Player);

		TargetLeftArmRotation = LeftArmRotation;
		TargetLeftLegRotation = LeftLegRotation;
		TargetRightArmRotation = RightArmRotation;
		TargetRightLegRotation = RightLegRotation;

		if(MainPlayer == nullptr)
		{
			MainPlayer = Player;
		}
		if(PlayerInt == 1)
		{
			TargetMovementIntensity = 1;
			AcceleratedFloatMovementIntesity.Value = 0.75f;
		}
	}
	UFUNCTION(NetFunction)
	void NetRemovePlayer(AHazePlayerCharacter Player)
	{
		PlayerInt --;
		CheckPlayers(Player);

		if(PlayerInt == 0)
		{
			TargetMovementIntensity = 0;
			AcceleratedFloatMovementIntesity.Value = 1.0f;
			MovementIntensityLerpSpeed = 20;
			bMovingUp = false;
			MainPlayer = nullptr;
			HasExited = true;
			HasEntered = false;
			TargetLeftArmRotation = 0;
			TargetLeftLegRotation = 0;
			TargetRightArmRotation = 0;
			TargetRightLegRotation = 0;
			SwingTargetLocationZ = 0;
		}
		if(PlayerInt == 1)
		{
			if(Player == Game::GetCody())
			{
				MainPlayer = Game::GetMay();
			}
			else
			{
				MainPlayer = Game::GetCody();
			}
		}
	}

	UFUNCTION()
	void CheckPlayers(AHazePlayerCharacter Player)
	{	
		if(PlayerInt == 0)
		{
			SoundPlaying = false;	
			HazeAkComp.HazePostEvent(StopMovementAudioEvent);
		}
		else if(PlayerInt == 1)
		{
			if(SoundPlaying == false)
			{
				SoundPlaying = true;
				HazeAkComp.HazePostEvent(StartMovementAudioEvent);
			}
		}
	}
}

