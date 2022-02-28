import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

class AFlexingSaw : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collider;

	UPROPERTY(DefaultComponent)
	UBoxComponent Grip1;

	UPROPERTY(DefaultComponent)
	UBoxComponent Grip2;

	UPROPERTY(DefaultComponent)
	UPoseableMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SawMovementAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SawJumpOffAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SawGroundpoundedAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect JumpOffForceFeedback;;

	// UPROPERTY()
	// float MoveVelocity;

	UPROPERTY()
	float VelocityNormalized;

	UPROPERTY()
	float PitchNormalized;

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	FHazeAcceleratedFloat Float;

	AHazePlayerCharacter PlayerBeingLaunched;

	FRotator Bone1StartRotation;
	FRotator Bone2StartRotation;
	FRotator Bone3StartRotation;
	FRotator Bone4StartRotation;
	FRotator Bone5StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		FActorGroundPoundedDelegate OnGroundPound;
		OnGroundPound.BindUFunction(this, n"OnActorGroundPounded");
		BindOnActorGroundPounded(this, OnGroundPound);

		Bone1StartRotation = Mesh.GetBoneRotationByName(n"Saw1", EBoneSpaces::ComponentSpace);
		Bone2StartRotation = Mesh.GetBoneRotationByName(n"Saw2", EBoneSpaces::ComponentSpace);
		Bone3StartRotation = Mesh.GetBoneRotationByName(n"Saw3", EBoneSpaces::ComponentSpace);
		Bone4StartRotation = Mesh.GetBoneRotationByName(n"Saw4", EBoneSpaces::ComponentSpace);
		Bone5StartRotation = Mesh.GetBoneRotationByName(n"Saw5", EBoneSpaces::ComponentSpace);

		HazeAkComp.HazePostEvent(SawMovementAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnActorGroundPounded(AHazePlayerCharacter Player)
	{
		Float.AccelerateTo(1, 0.01f, ActorDeltaSeconds);
		Player.PlayerHazeAkComp.HazePostEvent(SawGroundpoundedAudioEvent);

		if (Player.HasControl())
		{
			System::SetTimer(this, n"LaunchPlayer", 0.15f, false);
			PlayerBeingLaunched = Player;
		}
	}

	UFUNCTION()
	void LaunchPlayer()
	{
		PlayerBeingLaunched.SetCapabilityAttributeValue(n"VerticalVelocity", 1750);
		PlayerBeingLaunched.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", 0.f);
		PlayerBeingLaunched.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		OverlappingPlayers.Add(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Remove(Player);

		if(PitchNormalized > 0.01f)
		{
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Shed_Awakening_Platform_FlexingSaw_RotationPitch", PitchNormalized);
			Player.PlayerHazeAkComp.HazePostEvent(SawJumpOffAudioEvent);
		}

		Player.PlayForceFeedback(JumpOffForceFeedback, false, true, n"FlexingSaw");
	}

	float GetAccelerationNormalized() property
	{
		float LargestDistance = 0;

		for(auto Player : OverlappingPlayers)
		{
			float DistToPlayer = Root.WorldLocation.Distance(Player.ActorLocation);
			LargestDistance += DistToPlayer;
		}

		return LargestDistance / 1200; 
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		if (OverlappingPlayers.Num() == 0)
		{
			Float.SpringTo(AccelerationNormalized, 555.5f, 0.1f, DeltaSeconds);
			
		}
		else
		{
			Float.AccelerateTo(AccelerationNormalized, 0.5f, DeltaSeconds);
		}
		
		UpdateBones(Float.Value);

		//MoveVelocity = (FMath::Abs(Float.Velocity) / 7);
		VelocityNormalized = FMath::Abs(FMath::GetMappedRangeValueClamped(FVector2D(-5.f, 5.f), FVector2D(-1.f, 1.f), Float.Velocity));
		HazeAkComp.SetRTPCValue("Rtpc_Shed_Awakening_Platform_FlexingSaw_RotationSpeed", VelocityNormalized, 100);

	}

	void UpdateBones(float ZOffset)
	{
		FRotator Bone1Rotation = Bone1StartRotation;
		FRotator Bone2Rotation = Bone2StartRotation;
		FRotator Bone3Rotation = Bone3StartRotation;
		FRotator Bone4Rotation = Bone4StartRotation;
		FRotator Bone5Rotation = Bone5StartRotation;

		Bone1Rotation.Pitch += 25;
		Bone2Rotation.Pitch += 25;
		Bone3Rotation.Pitch += 25;
		Bone4Rotation.Pitch += 25;
		Bone5Rotation.Pitch += 25;

		Bone1Rotation = FMath::LerpShortestPath(Bone1StartRotation, Bone1Rotation, ZOffset);
		Bone2Rotation = FMath::LerpShortestPath(Bone2StartRotation, Bone2Rotation, ZOffset);
		Bone3Rotation = FMath::LerpShortestPath(Bone3StartRotation, Bone3Rotation, ZOffset);
		Bone4Rotation = FMath::LerpShortestPath(Bone4StartRotation, Bone4Rotation, ZOffset);
		Bone5Rotation = FMath::LerpShortestPath(Bone5StartRotation, Bone5Rotation, ZOffset);

		Mesh.SetBoneRotationByName(n"Saw1", Bone1Rotation, EBoneSpaces::ComponentSpace);
		Mesh.SetBoneRotationByName(n"Saw2", Bone2Rotation, EBoneSpaces::ComponentSpace);
		Mesh.SetBoneRotationByName(n"Saw3", Bone3Rotation, EBoneSpaces::ComponentSpace);
		Mesh.SetBoneRotationByName(n"Saw4", Bone4Rotation, EBoneSpaces::ComponentSpace);
		Mesh.SetBoneRotationByName(n"Saw5", Bone5Rotation, EBoneSpaces::ComponentSpace);

		PitchNormalized = FMath::GetMappedRangeValueClamped(FVector2D(70.f, 88.f), FVector2D(1.f, 0.f), Bone1Rotation.Pitch);
		HazeAkComp.SetRTPCValue("Rtpc_Shed_Awakening_Platform_FlexingSaw_RotationPitch", Bone1Rotation.Pitch);
	}
}