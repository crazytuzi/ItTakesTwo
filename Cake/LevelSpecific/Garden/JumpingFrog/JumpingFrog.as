import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.JumpingFrog.GardenFly;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogTags;
import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenFrog;

import void AddJumpingFrog(AJumpingFrog, AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent";
import Vino.Tutorial.TutorialPrompt;
import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.Camera.Settings.CameraLazyChaseSettings;
import Cake.LevelSpecific.Garden.VOBanks.GardenFrogPondVOBank;


enum EJumpingFrogMoveInputType
{
	Mash,
	Hold
}

class UJumpingFrogMovementSettings : UDataAsset
{
	UPROPERTY(Category = "Ground")
	float MoveSpeed = 350;

	UPROPERTY(Category = "Ground")
	float FastMoveSpeed = 650;

	UPROPERTY(Category = "Ground")
	EJumpingFrogMoveInputType TriggerFastMoveInputType = EJumpingFrogMoveInputType::Hold;

	// How fast the character will turn in radians per second while on the ground.
	UPROPERTY(Category = "Ground")
	float GroundRotationSpeed = 2.f;

	// How fast the character will turn in radians per second while on the ground and charging.
	UPROPERTY(Category = "Ground")
	float GroundRotationSpeedAtMaxPitch = 0.2f;

	// Set what value we should clamp downwards velocity to.
	UPROPERTY(Category = "Air")
	float GravityMultiplier = 10.f;

	// Set what value we should clamp downwards velocity to.
	UPROPERTY(Category = "Air")
	float MaxFallSpeed = 4000.f;
	
	// Without this, the speed in the air can be inifinite
	UPROPERTY(Category = "Air")
	bool bUseMaxAirSpeed = true;

	/* How fast you will move in the air moving forward. If your inital speed is greater than this, you will decelerate towards this
	*/
	UPROPERTY(Category = "Air", meta = (EditCondition = "bUseMaxAirSpeed"))
	float MaxAirSpeed = 4000.f;
	
	// The 'MaxAirSpeed' is multiplied with this. This is the sticks input amount against the forward direction
	// No input will use the 'ZeroInputValueOnTheMaxAirSpeedMultiplier'
	UPROPERTY(Category = "Air", meta = (EditCondition = "bUseMaxAirSpeed"))
	FRuntimeFloatCurve MaxAirSpeedMultiplierInRelationToInputAgainstForward;

	UPROPERTY(Category = "Air", meta = (EditCondition = "bUseMaxAirSpeed"))
	float ZeroInputValueOnTheMaxAirSpeedMultiplier = 1.f;

	// How fast the actor will accelerate towards its wanted strafe value while in the air.
	UPROPERTY(Category = "Air")
	float AirControlStrafeSpeed = 900.f;

	/* How fast you will stop the current forward velocity if you are steering backwards */
	UPROPERTY(Category = "Air")
	float AirBreakSpeed = 1000.f;

	/* How fast you will accelerate the current forward velocity if you are steering forward */
	UPROPERTY(Category = "Air")
	float AirAccelerationSpeed = 1000.f;
    
	// How fast the character will turn in radians per second while in the air.
	UPROPERTY(Category = "Air")
	float AirRotationSpeed = 0.f;

	// At what distance the frog will trace the grond and trigger a landing animation
	UPROPERTY(Category = "Air")
	float TraceGroundDistance = 1000.f;

	/* This will affect how fast you rotate and how much of the current stick input is valid
	 * The air control amount compared to the current vertical movement direction
	 * Time: -1; Going straight down, 1; Going straigh up 
	 * Value: should be 0 to 1. The air control amount percentage
	*/
	UPROPERTY(Category = "Air")
	FRuntimeFloatCurve AirControlAmountInRelationToHorizontalAngle;

	/* Changes the gravity multiplier depening on the vertical velocity in relation to the world up
	 * Time: -1; Going straight down, 1; Going straigh up 
	 * Value: The gravity percentage amount of the gravity multiplier
	*/
	UPROPERTY(Category = "Jump")
	FRuntimeFloatCurve GravityMultiplierInRelationToHorizontalAngle;

	// The force that will throw the frog up
	UPROPERTY(Category = "Jump")
	float JumpForce = 6000.f;

	// During this time, the jumpforce is still added, making the frog go higher
	UPROPERTY(Category = "Jump")
	float MaxJumpInputTime = 0.2f;

	// How much of the current velocity amount that should be inherited when the jump is triggered
	UPROPERTY(Category = "Jump")
	float VelocityInheritancePercentage = 1.f;

	// This amount will be added to the forward velocity when the jump is triggered combined with the 'JumpForwardForceStickInputMultiplier'
	UPROPERTY(Category = "Jump")
	float JumpForwardForce = 0.f;

	// This amount will be added to the forward velocity when the jump is triggered combined with the 'JumpForwardForce'
	UPROPERTY(Category = "Jump")
	FHazeMinMax JumpForwardForceStickInputMultiplier = FHazeMinMax(0.f, 1.f);

	// How long time from landing until a new jump can trigger
	UPROPERTY(Category = "Jump")
	float RetriggerJumpDelay = 0.2f;

	// How long after you leave an edge and become airbourne you can still jump
	UPROPERTY(Category = "Jump")
	float AllowEdgeJumpTime = 0.2f;

	// How long until you can move or after the jump is done
	UPROPERTY(Category = "Ground")
	float MovementDelayAfterJump = 0.;

	UPROPERTY(Category = "Impact")
	float ImpulseScaler = 0.7f;

	UPROPERTY(Category = "Impact")
	float MaxImpulse = 700.0f;

	UPROPERTY(Category = "Impact")
	float MinImpulse = 300.0f;
}

class UHazeFrogMovementComponent : UHazeMovementComponent
{
	AJumpingFrog OwningFrog;

	bool bIsMovingFast = false;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		Super::BeginPlay();
		OwningFrog = Cast<AJumpingFrog>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	float GetGravityMultiplier() const
	{
		if(IsGrounded() || OwningFrog.bIsQuickJumping)
		{	
			// We launch with the gravity multiplier
			return -OwningFrog.MovementSettings.GravityMultiplier;
		}
		else
		{
			FRuntimeFloatCurve GravityCurve = OwningFrog.MovementSettings.GravityMultiplierInRelationToHorizontalAngle;
			const float VelocityAlpha = GetWorldUp().DotProduct(GetVelocity().GetSafeNormal());	
			const float FinalCurveValue = GravityCurve.GetFloatValue(VelocityAlpha, 1.f);
			return -OwningFrog.MovementSettings.GravityMultiplier * FinalCurveValue;
		}
	}

	float GetAirControlAmount()const
	{
		FRuntimeFloatCurve AirControlCurve = OwningFrog.MovementSettings.AirControlAmountInRelationToHorizontalAngle;
		const float VelocityAlpha = GetWorldUp().DotProduct(GetVelocity().GetSafeNormal());	
		const float FinalCurveValue = AirControlCurve.GetFloatValue(VelocityAlpha, 0.f);
		return FMath::Max(FinalCurveValue, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	float GetRotationSpeed()const
	{
		if(OwningFrog.VerticalTravelDirection == 0)
		{
			if(IsGrounded())
				return FMath::Lerp(OwningFrog.MovementSettings.GroundRotationSpeed, OwningFrog.MovementSettings.GroundRotationSpeedAtMaxPitch, OwningFrog.BlendSpaceCharge);
			else
				return 0.f;
		}
		else
		{
			if(OwningFrog.bBouncing)
				return 0.f;
			else
				return OwningFrog.MovementSettings.AirRotationSpeed * GetAirControlAmount();
		}	
	}

	UFUNCTION(BlueprintOverride)
	float GetMoveSpeed() const
	{
		if(bIsMovingFast)
			return OwningFrog.MovementSettings.FastMoveSpeed;
		else
			return OwningFrog.MovementSettings.MoveSpeed;
	}

	UFUNCTION(BlueprintOverride)
	float GetMaxFallSpeed() const
	{
		return OwningFrog.MovementSettings.MaxFallSpeed;
	}
}

UCLASS(Abstract)
class AJumpingFrog : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = RootComponent)
    UInteractionComponent InteractionPoint;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USceneComponent DismountLocation;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UNiagaraComponent TongueComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent FrogHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeFrogMovementComponent FrogMoveComp;
	default FrogMoveComp.bDepenetrateOutOfOtherMovementComponents = false;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::High;
	default CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	default ReplicateAsMovingActor();

	UPROPERTY(EditDefaultsOnly, Category = "Death")
	TSubclassOf<UPlayerDeathEffect> WaterDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Death")
	TSubclassOf<UPlayerDeathEffect> PiercedDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Death")
	TSubclassOf<UPlayerDeathEffect> SlimeDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Tutorial")
	FTutorialPrompt JumpPrompt;
	default JumpPrompt.Action = ActionNames::MovementJump;
	//default JumpPrompt.Text = FText::FromString("Jump");
	default JumpPrompt.MaximumDuration = 10.f;
	default JumpPrompt.Mode = ETutorialPromptMode::Default;

	UPROPERTY(EditDefaultsOnly, Category = "Tutorial")
	FTutorialPrompt DashPrompt;
	default DashPrompt.Action = ActionNames::MovementDash;
	//default DashPrompt.Text = FText::FromString("Run");
	default DashPrompt.MaximumDuration = 10.f;
	default DashPrompt.Mode = ETutorialPromptMode::Default;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float RespawnTime = 2.f;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UGardenFrogPondVOBank VOBank;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<UHazeCapability> DeathCapability;

	UPROPERTY(EditDefaultsOnly)
	UJumpingFrogMovementSettings MovementSettings;
	
	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet RequiredSheet;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset FrogCamSettings;

	UPROPERTY(EditDefaultsOnly)
	UCameraLazyChaseSettings CameraLazyChaseSettings;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactForceFeedback;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ChargeForceFeedback;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect JumpForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LandForceFeedback;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bMounted = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUseMountAnimation = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCharging = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bJumping = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bBouncing = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bShouldActivateTongue = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bTongueIsActive = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bWaterJumping = false;
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDying = false;

	// The current distance to the ground when VerticalTravelDirection == -1
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float DistanceToGround = 0;

	// (-1 -> 1, where -1 is left max input)
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float BlendSpaceTurn = 0;

	// (0 -> 1, where 1 is max charget)
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float BlendSpaceCharge = 0;

	// (-1, 0 ,1 where -1 is descending)
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float VerticalTravelDirection = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsQuickJumping = false;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bIsMaysFrog = false;

	//bool bLanded = false;

	UPROPERTY(NotEditable)
	bool bShouldPlayJumpReactionVO = false;

	FVector2D CurrentMovementInput = FVector2D::ZeroVector;

	AGardenFly CurrentFlyTarget;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter MountedPlayer;
	FVector JumpForce;
	float CurrentChargeDelay = 0;
	float CurrentMovementDelay = 0;
	float ForceQuickJumpTimeLeft = 0;

	FTransform RespawnTransform;

	int DeathCount = 0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {	
		FrogMoveComp.Setup(CapsuleComponent);
		DisableMovementComponent(this);

		InteractionPoint.OnActivated.AddUFunction(this, n"InteractionActivated");
		InteractionPoint.SetWorldLocation(Mesh.GetSocketLocation(n"Totem"));

		AddCapability(n"JumpingFrogJumpNextGenCapability");
		AddCapability(n"JumpingFrogMovementCapability");
		//AddCapability(n"JumpingFrogFacingDirectionCapability");
		//AddCapability(n"JumpingFrogTongueCapability");

		if(DeathCapability.IsValid())
			AddCapability(DeathCapability);

		//AddCapability(n"JumpingFrogDeathCheckCapability");
		AddCapability(n"JumpingFrogAlignMeshCapability");

		if(bIsMaysFrog)
			InteractionPoint.SetExclusiveForPlayer(EHazePlayer::May, true);
		else
			InteractionPoint.SetExclusiveForPlayer(EHazePlayer::Cody, true);
    }

	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
	{
		// We store the input in the crumb
		CurrentChargeDelay = FMath::Max(CurrentChargeDelay - DeltaTime, 0.f);
		CurrentMovementDelay = FMath::Max(CurrentMovementDelay - DeltaTime, 0.f);
		ForceQuickJumpTimeLeft = FMath::Max(ForceQuickJumpTimeLeft - DeltaTime, 0.f);

		if(HasControl())
		{
			FVector InputParams;
			InputParams.X = BlendSpaceTurn * 100;
			InputParams.Y = BlendSpaceCharge * 100;
			InputParams.Z = VerticalTravelDirection * 100;
			CrumbComp.SetCustomCrumbVector(InputParams);
		}
		else if(MountedPlayer != nullptr)
		{
			FHazeActorReplicationFinalized ReplicatedInput;
			CrumbComp.GetCurrentReplicatedData(ReplicatedInput);
			BlendSpaceTurn = ReplicatedInput.CustomCrumbVector.X / 100.f;
			BlendSpaceCharge = ReplicatedInput.CustomCrumbVector.Y / 100.f;
			VerticalTravelDirection = FMath::RoundToInt(ReplicatedInput.CustomCrumbVector.Z / 100.f);
		}
	}

    UFUNCTION(NotBlueprintCallable)
    void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		MountAnimal(Player);
    }

	UFUNCTION()
	void MountAnimal(AHazePlayerCharacter Player, bool bSkipMountedAnimation = false, bool bSkipMountedSound = false)
	{
		if(Player == nullptr)
			return;

		InteractionPoint.Disable(n"Mounted");
		bMounted = true;
		MountedPlayer = Player;
		bUseMountAnimation = !bSkipMountedAnimation;
		Player.AddCapabilitySheet(RequiredSheet, EHazeCapabilitySheetPriority::Normal, this);
		SetControlSide(Player);	
		AddJumpingFrog(this, Player);

		if(!bSkipMountedSound)
			SetCapabilityActionState(n"AudioFrogMount", EHazeActionState::ActiveForOneFrame);
	}

	void FrogDismounted()
	{
		MountedPlayer.TriggerMovementTransition(this);

		MountedPlayer.SetActorLocation(DismountLocation.WorldLocation);
		FVector Impulse = GetActorForwardVector();
		Impulse *= 500.f;
		Impulse += GetActorUpVector() * 1200.f;
		MountedPlayer.AddImpulse(Impulse);

		MountedPlayer.RemoveAllCapabilitySheetsByInstigator(this);

		MountedPlayer = nullptr;
		bMounted = false;
		InteractionPoint.EnableAfterFullSyncPoint(n"Mounted");

		bCharging = false;
		BlendSpaceCharge = 0.f;
		CurrentMovementInput = FVector2D::ZeroVector;
		bShouldActivateTongue = false;
		bTongueIsActive = false;
		SetCapabilityActionState(n"AudioFrogDismount", EHazeActionState::ActiveForOneFrame);
	}

	void TriggerJump(FVector Force)
	{
		JumpForce = Force;
		bJumping = true;
	}	

	UFUNCTION()
	void MakeAlive()
	{
		//bDying = false;
	}
}

