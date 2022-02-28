import Cake.Weapons.Nail.NailWielderComponent;

class UTutorialNailThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	
    AHazePlayerCharacter Player;
	UNailWielderComponent WielderComponent;

    UPROPERTY(Category = "Widget")
    TSubclassOf<UHazeUserWidget> WidgetClass;
	UHazeUserWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
        ensure(Player != nullptr);

		WielderComponent = UNailWielderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WielderComponent == nullptr || WielderComponent.NailsEquippedToBack.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

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
		Widget = Player.AddWidget(WidgetClass);
		Widget.AttachWidgetToActor(WielderComponent.NailsEquippedToBack[0], n"Head");
	}
}