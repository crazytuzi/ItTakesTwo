import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

event void FOnMagnetActivatedEvent(UMagneticComponent Magnet, bool bEqualPolarities);
event void FOnMagnetDeactivatedEvent(UMagneticComponent Magnet, bool bEqualPolarities);

event void FOnMagnetVisualEvent();

event void FOnMagnetLaunchEvent();
event void FOnMagnetBoostEvent();

event void FOnMagnetPushEvent();
event void FOnMagnetPullEvent();

event void FOnMagnetBadInteractionEvent();

// Magnetic player attraction
event void FOnMPAChargeEvent();
event void FOnMPALaunchEvent();
event void FOnMPAPerchEvent();
event void FOnMPAPlayersConvergedEvent();

enum EPlayerMagnetState
{
	Pulling = -1,
	Idle,
	Pushing
};

class APlayerMagnetActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USkeletalMeshComponent MagnetMesh;
	default MagnetMesh.bRenderStatic = true;
	default MagnetMesh.bUpdateOverlapsOnAnimationFinalize = false;
	default MagnetMesh.bComponentUseFixedSkelBounds = true;
	default MagnetMesh.AnimationMode = EAnimationMode::AnimationSingleNode;
	default MagnetMesh.bAllowAnimCurveEvaluation = false;
	default MagnetMesh.bNoSkeletonUpdate = true;
	default MagnetMesh.AddTag(ComponentTags::HideOnCameraOverlap);

	UPROPERTY(BlueprintReadOnly)
	EPlayerMagnetState MagnetState = EPlayerMagnetState::Idle;


	// Normalized
	UPROPERTY(BlueprintReadOnly)
	float NormalDistanceToTargetMagnet = 1.f;

	// Normalized
	UPROPERTY(BlueprintReadOnly)
	float MagnetChargeProgress = 0.f;

	// Normalized
	UPROPERTY(BlueprintReadOnly)
	float MagnetLaunchProgress = 0.f;

	// Amount of magnet movement between frames
	UPROPERTY(BlueprintReadOnly)
	float ActivatedMagnetMovementDelta = 0.f;


	UPROPERTY(Category = "VFX")
	UNiagaraSystem CodyMagnetTrail;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem MayMagnetTrail;

	UNiagaraComponent SpawnedTrailEffect;

	private FVector MagnetEffectLocation = FVector(0.f, 0.f, 50.f);

	AHazePlayerCharacter OwningPlayer;


	// MAGNET ACTUATING /////////////////////////////
	// Player started actuating some magnet
	UPROPERTY()
	FOnMagnetActivatedEvent OnMagnetActivated;

	// Player stopped actuating magnet
	UPROPERTY()
	FOnMagnetDeactivatedEvent OnMagnetDeactivated;


	// TARGETING ////////////////////////////////////
	// Player started targetting a magnet
	UPROPERTY()
	FOnMagnetVisualEvent OnMagnetVisualStarted;

	// Player stopped targetting magnet
	UPROPERTY()
	FOnMagnetVisualEvent OnMagnetVisualStopped;

	// Player changed magnet target without stopping
	UPROPERTY()
	FOnMagnetVisualEvent OnTargetMagnetChanged;


	// LAUNCHING ////////////////////////////////////
	// Player started charging magnet launch
	UPROPERTY()
	FOnMagnetLaunchEvent OnLaunchChargeStarted;

	// Player completed charge
	UPROPERTY()
	FOnMagnetLaunchEvent OnLaunchChargeDone;

	// Player cancelled magnet launch
	UPROPERTY()
	FOnMagnetLaunchEvent OnLaunchChargeCancelled;

	// Launch charge completed and player is flying towards magnet
	UPROPERTY()
	FOnMagnetLaunchEvent OnLaunch;

	// Player arrived to magnet
	UPROPERTY()
	FOnMagnetLaunchEvent OnLaunchDone;


	// PERCHING /////////////////////////////////////
	// Flying towards magnet (magnet launch) is done and player is attached to magnet
	UPROPERTY()
	FOnMagnetLaunchEvent OnMagnetPerchStarted;

	// Magnet is moving and its rotation has changed, hence player position has changed
	UPROPERTY()
	FOnMagnetLaunchEvent OnMagnetPerchPositionChange;

	// Player is dettaching and jumping away from magnet perch
	UPROPERTY()
	FOnMagnetLaunchEvent OnMagnetPerchDone;


	// BOOST ////////////////////////////////////////
	// Player started charging boost
	UPROPERTY()
	FOnMagnetBoostEvent OnBoostChargeStarted;

	// Boost charge was cancelled by player
	UPROPERTY()
	FOnMagnetBoostEvent OnBoostChargeCancelled;

	// Boost charge is done and player is now boosting away!
	UPROPERTY()
 	FOnMagnetBoostEvent OnBoost;


	// PUSH /////////////////////////////////////////
	// Player is pushing object with magnet
	UPROPERTY()
	FOnMagnetPushEvent OnMagnetPushStarted;

	// Magnet pushing stopped
	UPROPERTY()
	FOnMagnetPushEvent OnMagnetPushStopped;


	// PULL /////////////////////////////////////////
	// Player is pulling object with magnet
	UPROPERTY()
	FOnMagnetPullEvent OnMagnetPullStarted;

	// Magnet pulling stopped
	UPROPERTY()
	FOnMagnetPullEvent OnMagnetPullStopped;


	// MISC /////////////////////////////////////////
	// Wrong player is interacting with magnet
	UPROPERTY()
	FOnMagnetBadInteractionEvent OnMagnetBadInteraction;


	// MAGNETIC PLAYER ATTRACTION ///////////////////
	// Player started charging magnet
	UPROPERTY()
	FOnMPAChargeEvent OnMPAChargeStarted;

	// Player charged magnet
	UPROPERTY()
	FOnMPAChargeEvent OnMPAChargeDone;

	// Charging was cancelled
	UPROPERTY()
	FOnMPAChargeEvent OnMPAChargeCancelled;

	// Player started launching towards other player
	UPROPERTY()
	FOnMPALaunchEvent OnMPALaunch;

	// Player reached other player and will start piggybacking
	UPROPERTY()
	FOnMPAPerchEvent OnMPAPerchStarted;

	// Player will jump away from other player
	UPROPERTY()
	FOnMPAPerchEvent OnMPAPerchDone;

	// Both players launched to each other and reached the meeting point
	UPROPERTY()
	FOnMPAPlayersConvergedEvent OnMPAPlayersConverged;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Fixes weird ass relative offset that shows up from Satan knows where
		MagnetMesh.SetRelativeLocation(FVector::ZeroVector);
		MagnetMesh.SetRelativeRotation(FRotator::ZeroRotator);
		MagnetMesh.SetWorldScale3D(FVector::OneVector);
	}

	UFUNCTION()
	void Initialize(AHazePlayerCharacter PlayerCharacter, USkeletalMesh MagnetMeshType)
	{
		OwningPlayer = PlayerCharacter;

		// Create mesh component and assign player-specific skeletal mesh
		MagnetMesh.SetSkeletalMesh(MagnetMeshType);

		// Attach to player's backpack bone and add to outline
		AttachToActor(PlayerCharacter, n"Backpack", EAttachmentRule::SnapToTarget);
		AddMeshToPlayerOutline(MagnetMesh, PlayerCharacter, this);

		// Spawn trail effect
		UNiagaraSystem MagnetTrailSystem = PlayerCharacter.IsCody() ? CodyMagnetTrail : MayMagnetTrail;
		SpawnedTrailEffect = Niagara::SpawnSystemAttached(MagnetTrailSystem, MagnetMesh, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(SpawnedTrailEffect != nullptr)
		{
			SpawnedTrailEffect.DestroyComponent(this);
			SpawnedTrailEffect = nullptr;
		}
	}

	UFUNCTION()
	FVector GetMagnetEffectWorldLocation()
	{
		return ActorTransform.TransformPosition(MagnetEffectLocation);
	}

	float GetMagnetStateAsFloat()
	{
		return float(MagnetState);
	}
}