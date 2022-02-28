import Cake.Weapons.AimTargetIndicator.AimTargetIndicatorComponent;

struct FAimTargetIndicatorWidgetPair
{
	FAimTargetIndicatorWidgetPair(USceneComponent InTarget, UAimTargetIndicatorWidget InWidget)
	{
		Target = InTarget;
		Widget = InWidget;
	}

	USceneComponent Target;
	UAimTargetIndicatorWidget Widget;
}

class UAimTargetIndicatorCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AimTargetIndicator");
	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UAimTargetIndicatorComponent AimTargetIndicator;
	UAimTargetIndicatorWidgetComponent WidgetComponent;

	

	TArray<FAimTargetIndicatorWidgetPair>  TargetWidgetPairs;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimTargetIndicator = UAimTargetIndicatorComponent::GetOrCreate(Player);
		WidgetComponent = UAimTargetIndicatorWidgetComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (AimTargetIndicator.bShouldBeVisible)
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
        else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!AimTargetIndicator.bShouldBeVisible)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		for (auto Target : AimTargetIndicator.AimTargetIndicators)
		{
			UAimTargetIndicatorWidget Widget = Cast<UAimTargetIndicatorWidget>(Player.AddWidget(WidgetComponent.WidgetClass));
			Widget.AttachWidgetToComponent(Target);
			TargetWidgetPairs.Add(FAimTargetIndicatorWidgetPair(Target, Widget));
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for (auto Pair : TargetWidgetPairs)
		{
			Player.RemoveWidget(Pair.Widget);
		}
		TargetWidgetPairs.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Added return since target indicator shouldnt be a thing?
		return;
		// TArray<AActor> ActorsToIgnore;
		// ActorsToIgnore.Add(Player);
		// for (auto Pair : TargetWidgetPairs)
		// {
		// 	FVector Start = Player.GetPlayerViewLocation();
		// 	FHitResult Hit;
		// 	if (System::LineTraceSingle(Start, Pair.Target.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true))
		// 	{
		// 		Pair.Widget.bOccluded = true;
		// 	}

		// 	else
		// 	{
		// 		Pair.Widget.bOccluded = false;
		// 	}
		// }
	}
}