import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

class UPlayerFishingControlBaseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerFishingControlBaseCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerFishingComponent PlayerComp;
	ARodBase RodBase;

	float TargetInputSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerFishingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.FishingState == EFishingState::Default)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.FishingState != EFishingState::Default)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.HideTutorialPrompt(Player);

		PlayerComp.ShowCancelInteractionPrompt(Player);
		PlayerComp.ShowRightTriggerCastPrompt(Player);
		
		if (RodBase == nullptr)
			RodBase = Cast<ARodBase>(PlayerComp.RodBase);
		
		Player.AttachToComponent(RodBase.BaseSkeleton, n"PlayerAttach_Socket", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		PlayerComp.bCanCancelFishing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerComp.HideCancelInteractionPrompt(Player);
		PlayerComp.HideTutorialPrompt(Player);
		PlayerComp.TargetRotationInput = 0.f;
		PlayerComp.InputValue = 0.f;
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (IsActioning(ActionNames::PrimaryLevelAbility) && HasControl())
			NetSetWindingUp();

		PlayerComp.InputValue = GetAttributeVector2D(AttributeVectorNames::MovementRaw).Y;

		if (PlayerComp.InputValue != 0.f)
		{
			if (PlayerComp.CurrentDotRight < 0.f)
			{
				if (PlayerComp.CurrentDotForward < PlayerComp.DotLeftMax)
				{
					if (PlayerComp.InputValue < 0.f)
					{
						PlayerComp.InputValue = 0.f;
						PlayerComp.InterpSpeed = PlayerComp.HaltInterpSpeed;
					}
				}
			}
			else if (PlayerComp.CurrentDotRight > 0.f)
			{
				if (PlayerComp.CurrentDotForward < PlayerComp.DotRightMax)
				{
					if (PlayerComp.InputValue > 0.f)
					{
						PlayerComp.InputValue = 0.f;
						PlayerComp.InterpSpeed = PlayerComp.HaltInterpSpeed;
					}
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetWindingUp()
	{
		PlayerComp.FishingState = EFishingState::WindingUp;
	}
}
