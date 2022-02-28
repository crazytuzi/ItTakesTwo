import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.MovementSettings;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Vino.Movement.Capabilities.Skydive.CharacterSkydiveComponent;

class UCharacterSkydiveCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);	
	default CapabilityTags.Add(MovementSystemTags::SkyDive);

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 170;

	AHazePlayerCharacter Player;
	UCharacterSkydiveComponent SkydiveComp;
	UPlayerHazeAkComponent PlayerHazeAkComp;
	UPlayerMovementAudioComponent AudioMoveComp;

	float FallingDuration = 0.f;
	float ActivationFallDuration = 0.6f;

	float HeightRange = 1500.f;

	FHitResult AsyncTraceResult;
	uint LastValidAsyncTraceFrame = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SkydiveComp = UCharacterSkydiveComponent::Get(Owner);
		PlayerHazeAkComp = UPlayerHazeAkComponent::Get(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		if (!IsBlocked() &&  MoveComp.Velocity.DotProduct(MoveComp.WorldUp) < 0.f)
			FallingDuration += Owner.ActorDeltaSeconds;
		else
			FallingDuration = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(n"SkyDive"))
		{
			if (!AreHighEnough())
				return EHazeNetworkActivation::DontActivate;

			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
		{	
			if (!HaveFallenForLongEnough())
				return EHazeNetworkActivation::DontActivate;

			if (!AreHighEnoughAsyncTrace())
				return EHazeNetworkActivation::DontActivate;		

			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{
		Player.SetCapabilityActionState(MovementActivationEvents::SkyDiving, EHazeActionState::Active);

		PlayerHazeAkComp.HazePostEvent(AudioMoveComp.FallingSkydivingEvents.StartSkydivingEvent);
		PlayerHazeAkComp.HazePostEvent(AudioMoveComp.EffortEvents.EffortBreathSkyDiveStartEvents);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ConsumeAction(MovementActivationEvents::SkyDiving);

		PlayerHazeAkComp.HazePostEvent(AudioMoveComp.FallingSkydivingEvents.StopSkydivingEvent);
		PlayerHazeAkComp.HazePostEvent(AudioMoveComp.EffortEvents.EffortBreathSkyDiveStopEvents);

		if (MoveComp.IsGrounded())
		{
			if (SkydiveComp.LandingCameraShake.Get() != nullptr)
				Player.PlayCameraShake(SkydiveComp.LandingCameraShake, 3.f);
			if (SkydiveComp.LandingForceFeedback != nullptr)
				Player.PlayForceFeedback(SkydiveComp.LandingForceFeedback, false, true, n"SkydiveLanding");

			FHazeCameraImpulse CamImpulse;
			CamImpulse.WorldSpaceImpulse = Player.MovementWorldUp * -3500.f;
			CamImpulse.Dampening = 0.25f;
			CamImpulse.ExpirationForce = 170.f;
			Player.ApplyCameraImpulse(CamImpulse, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SkyDive");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"SkyDive");
			
			CrumbComp.LeaveMovementCrumb();

			PlayerHazeAkComp.SetRTPCValue("Rtpc_Player_Falling_Duration", FallingDuration);
		}	
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{			
			FVector Velocity = MoveComp.Velocity;
			FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			FVector MoveRaw = GetAttributeVector(AttributeVectorNames::MovementRaw);

			FVector Blendspace = Player.ActorTransform.InverseTransformVector(MoveDirection);
			Player.SetAnimVectorParam(n"SkyDiveBlendspace", Blendspace);

			FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
			FVector TargetVelocity = MoveDirection * MoveComp.HorizontalAirSpeed;
			FVector NewHorizontalVelocity = FMath::VInterpConstantTo(HorizontalVelocity, TargetVelocity, DeltaTime, ActiveMovementSettings.AirControlLerpSpeed);

			FrameMove.ApplyVelocity(NewHorizontalVelocity);
			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.ApplyActorVerticalVelocity();
			FrameMove.ApplyGravityAcceleration();

			FVector FacingDirection = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
			if (FacingDirection.IsNearlyZero())
				FacingDirection = Owner.ActorForwardVector;
			FacingDirection.Normalize();			
			MoveComp.SetTargetFacingDirection(FacingDirection, 2.5f);
			if (!MoveDirection.IsNearlyZero())
				FrameMove.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}	
	}

	bool HaveFallenForLongEnough() const
	{
		return FallingDuration >= ActivationFallDuration;
	}

	bool AreHighEnough() const
	{
		
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(MoveComp);
		TraceParams.SetToLineTrace();
		TraceParams.From = Player.GetActorLocation();
		TraceParams.To = TraceParams.From - (MoveComp.WorldUp * HeightRange);

		if(IsDebugActive())
			TraceParams.DebugDrawTime = KINDA_SMALL_NUMBER;

		FHazeHitResult Hit;
		TraceParams.Trace(Hit);
		return !Hit.bBlockingHit;
	}

	bool AreHighEnoughAsyncTrace() const
	{
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(MoveComp);
		TraceParams.SetToLineTrace();
		TraceParams.From = Player.GetActorLocation();
		TraceParams.To = TraceParams.From - (MoveComp.WorldUp * HeightRange);

		if(IsDebugActive())
			TraceParams.DebugDrawTime = KINDA_SMALL_NUMBER;

		auto TraceComp = UHazeAsyncTraceComponent::GetOrCreate(Player);
		TraceComp.TraceSingle(TraceParams, this, n"AsyncTraceDone");
		
		if(LastValidAsyncTraceFrame == 0 || Time::GetFrameNumber() > LastValidAsyncTraceFrame + 1)
			return false;

		return !AsyncTraceResult.bBlockingHit;
	}

	UFUNCTION(NotBlueprintCallable)
	private void AsyncTraceDone(UObject Instigator, FName TraceId, TArray<FHitResult> Obstructions)
	{	
		LastValidAsyncTraceFrame = Time::GetFrameNumber();
		if(Obstructions.Num() > 0)
			AsyncTraceResult = Obstructions[0];
		else
			AsyncTraceResult = FHitResult();
	}
}
