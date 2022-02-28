import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallRewindComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Effects.PostProcess.PostProcessing;

class UClockworkLastBossFreeFallRewindCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"ClockworkLastBossFreeFallRewindCapability");
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::AirMovement);
	default CapabilityTags.Add(MovementSystemTags::Falling);

	default CapabilityDebugCategory = n"ClockworkLastBossFreeFallRewindCapability";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UClockworkLastBossFreeFallRewindComponent RewindComp;
	float TimerDuration = 5.f;
	float Timer = 5.f;

	UPROPERTY()
	UHazeLocomotionFeatureBase CodyFeature;

	UPROPERTY()
	UHazeLocomotionFeatureBase MayFeature;
	
	UHazeLocomotionFeatureBase FeatureToUse; 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		RewindComp = UClockworkLastBossFreeFallRewindComponent::Get(Player);

		FeatureToUse = Player == Game::GetCody() ? CodyFeature : MayFeature;
		Player.AddLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"FreeFallRewind"))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (IsActioning(n"FreeFallRewind"))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this, n"FreeFallRewind");
		RewindComp.StopStampingFreeFallTransform();
		Timer = TimerDuration;
		
		if (Player == Game::GetCody())
			UPostProcessingComponent::Get(Player).VHS = 1.f;

		Player.SetAnimBoolParam(n"FreeFallRewind", true); 
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.TriggerMovementTransition(this, n"FreeFallRewind");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Timer -= DeltaTime;

		float TransformDuration = TimerDuration / (RewindComp.TransformStampsArray.Num() - 1);
		int TransformIndex = FMath::CeilToInt(Timer / TransformDuration);
		TransformIndex = FMath::Clamp(TransformIndex, 1, RewindComp.TransformStampsArray.Num() - 1);

		FTransform A = RewindComp.TransformStampsArray[TransformIndex - 1];
		FTransform B = RewindComp.TransformStampsArray[TransformIndex];

		float ATime = (TransformIndex - 1) * TransformDuration; 
		float BTime = TransformIndex * TransformDuration; 

		float TimePercentage = (Timer - ATime) / TransformDuration;

		FVector LocationToLerp = FMath::Lerp(A.Location, B.Location, TimePercentage);
		LocationToLerp.Z = GetAttributeValue(n"FallCurrentHeight");
		FQuat RotationToLerp = FQuat::Slerp(A.Rotation, B.Rotation, TimePercentage);

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ClockworkFreeFallRewind");	
			FrameMove.ApplyDelta(LocationToLerp - Player.GetActorLocation());
			FrameMove.SetRotation(RotationToLerp);
			MoveCharacter(FrameMove, n"FreeFall");
		}
	}
}