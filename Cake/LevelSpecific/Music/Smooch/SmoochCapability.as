import Cake.LevelSpecific.Music.Smooch.Smooch;
import Cake.LevelSpecific.Music.Smooch.SmoochNames;

class USmoochCapability : UHazeCapability
{
	default CapabilityTags.Add(Smooch::Smooch);
	default CapabilityDebugCategory = n"Smooch";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	USmoochUserComponent SmoochComp;

	FHazeAcceleratedFloat AcceleratedTime;

	float BaseProgress = 0.f;
	float PeekProgress = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SmoochComp = USmoochUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, Smooch::Smooch, this);
		Player.AddLocomotionFeature(SmoochComp.AnimFeature[Player]);

		AcceleratedTime.SnapTo(0.f);
		BaseProgress = PeekProgress = 0.f;

		auto Button = Cast<USmoochHoldButtonWidget>(Player.AddWidget(SmoochComp.ButtonWidgetType));
		Button.AttachWidgetToComponent(Player.Mesh, n"Head");
		Button.SetWidgetRelativeAttachOffset(FVector(-12.f, 0.f, 15.f));
		Button.SetWidgetShowInFullscreen(true);
		Button.SetButtonScreenSpaceOffset(FVector2D(Player.IsMay() ? -200.f : 200.f, 0.f));
		Button.FadeIn();
		SmoochComp.ButtonWidget = Button;
		SmoochComp.bHasFinished = false;

		SmoochComp.OnSmoochBegin();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.RemoveLocomotionFeature(SmoochComp.AnimFeature[Player]);

		Player.RemoveWidget(SmoochComp.ButtonWidget);

		SmoochComp.OnSmoochEnd();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
        FHazeRequestLocomotionData AnimationRequest;
		AnimationRequest.AnimationTag = n"GrandFinaleKiss";

        Player.RequestLocomotion(AnimationRequest);
        float DeltaProgress = (1.f / SmoochHoldTime) * DeltaTime;

        if (SmoochComp.bIsHolding)
        {
        	if (GetSmoochNumPlayersHolding() == 2 && BaseProgress < SmoochMaxProgress)
        	{
        		BaseProgress = FMath::Min(BaseProgress + DeltaProgress, SmoochMaxProgress);
        		PeekProgress = FMath::Max(PeekProgress - DeltaProgress, 0.f);
        	}
        	else
        	{
        		PeekProgress = FMath::Min(PeekProgress + DeltaProgress, SmoochPeekPercent);
        	}
        }
        else
        {
    		PeekProgress = FMath::Max(PeekProgress - DeltaProgress, 0.f);
        }

		AcceleratedTime.AccelerateTo(BaseProgress + PeekProgress, 4.f, DeltaTime);
		SmoochComp.Progress = AcceleratedTime.Value;

		PrintToScreen("Progress: " + SmoochComp.Progress);

		if (SmoochComp.Progress > 1.f)
		{
			SmoochComp.Progress = 1.f;
			SmoochComp.bHasFinished = true;
		}
		else
		{
			SmoochComp.bHasFinished = false;
		}
	}

	float AdvancePercentTowards(float Percent, float Target, float DeltaTime)
	{
		return FMath::FInterpConstantTo(Percent, Target, 1.f / SmoochHoldTime, DeltaTime);
	}
}
