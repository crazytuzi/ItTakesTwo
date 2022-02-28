import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.BouncePad.BouncePad;
import Vino.Pickups.PlayerPickupComponent;
import Vino.BouncePad.BouncePadResponseComponent;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;

UCLASS(Abstract)
class UCharacterBouncePadCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"CharacterBouncePadCapability");

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 12;

	float VerticalVelocity;
	float VerticalVelocityModifier = 1.f;
	float HorizontalVelocityModifier = 0.5f;
	float MaximumHorizontalVelocity = 500.f;

	bool bGroundPounded = false;
	bool bValidActivation;

	UCharacterGroundPoundComponent GroundPoundComp = nullptr;

	AHazePlayerCharacter Player;

	FVector Velocity;
	FVector VelocityDirection;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY()
	TPerPlayer<UFoghornBarkDataAsset> BouncePadBark;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Super::Setup(SetupParams);

		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(n"Bouncing"))
        	return EHazeNetworkActivation::ActivateUsingCrumb;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GetActiveDuration() >= 0.3f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
	

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
        {
			OutParams.AddActionState(n"GroundPounded");
			if (!ConsumeAttribute(n"GroundPoundModifier", VerticalVelocityModifier))
				VerticalVelocityModifier = 1.25f;
        }
		Player.BlockCapabilities(MovementSystemTags::GroundPound, this);

		if (!ConsumeAttribute(n"VerticalVelocityDirection", VelocityDirection))
			VelocityDirection = MoveComp.WorldUp;

		if (ConsumeAction(n"PlayBounceAnimation") == EActionStateStatus::Active)
			OutParams.AddActionState(n"PlayBounceAnim");

		ConsumeAttribute(n"VerticalVelocity", VerticalVelocity);
		ConsumeAttribute(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Inactive);

		FVector CurMovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector Forward = MoveComp.TargetFacingRotation.Vector().ConstrainToPlane(VelocityDirection);
		Forward.Normalize();
        Velocity = Forward * Player.ActorVelocity * HorizontalVelocityModifier * CurMovementDirection;
		Velocity += VelocityDirection * VerticalVelocity * VerticalVelocityModifier;

		OutParams.AddVector(n"Velocity", Velocity);

		UObject BouncedObject;
		if (!ConsumeAttribute(n"BouncedObject", BouncedObject))
			BouncedObject = MoveComp.DownHit.Actor;

		if (BouncedObject != nullptr)
			OutParams.AddObject(n"BouncePad", BouncedObject);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bGroundPounded = ActivationParams.GetActionState(n"GroundPounded");
		GroundPoundComp.ResetState();

		if (ActivationParams.IsStale())
		{
			bValidActivation = false;
			return;
		}

		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		if (!HasControl())
			Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
		bValidActivation = true;

		Player.PlayCameraShake(CameraShakeClass);
		Player.PlayForceFeedback(ForceFeedbackEffect, false, true, n"Bounce");

		UFoghornBarkDataAsset BarkAsset = BouncePadBark[Player];
		if (BarkAsset != nullptr)
			PlayFoghornEffort(BouncePadBark[Player], nullptr);

		UObject BouncedObject = ActivationParams.GetObject(n"BouncePad");
		AHazeActor CurrentActor;
		if (BouncedObject != nullptr)
			CurrentActor = Cast<AHazeActor>(BouncedObject);
		UBouncePadResponseComponent BounceComp;
		if (CurrentActor != nullptr)
			BounceComp = UBouncePadResponseComponent::Get(CurrentActor);

		bool bPlayBounceAnimation = true;
		if (BounceComp != nullptr)
			bPlayBounceAnimation = BounceComp.bPlayBounceAnimation;

		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::Get(Player);
		if (PickupComp != nullptr && PickupComp.IsHoldingObject() && PickupComp.GetPickupType() == EPickupType::Big ||
			PickupComp != nullptr && PickupComp.IsHoldingObject() && PickupComp.GetPickupType() == EPickupType::HeavySmall)
		{
			bPlayBounceAnimation = false;
		}

		if (bPlayBounceAnimation)
		{
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Bounce");
			MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
			MoveCharacter(MoveData, n"Bounce");
		}

		FVector BounceVelocity = ActivationParams.GetVector(n"Velocity");
		MoveComp.SetVelocity(BounceVelocity);
		MoveComp.AddImpulse(BounceVelocity);

		if (BounceComp != nullptr)
			BounceComp.OnBounce.Broadcast(Player, bGroundPounded);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (bValidActivation)
		{
			Player.UnblockCapabilities(MovementSystemTags::Jump, this);
			Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		}

		bGroundPounded = false;
		VerticalVelocityModifier = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Inactive);
    }
}
