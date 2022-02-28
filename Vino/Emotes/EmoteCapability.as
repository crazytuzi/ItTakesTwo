import Vino.Emotes.EmoteComponent;
import Peanuts.SelectionWheel.SelectionWheelWidget;
import Peanuts.SelectionWheel.SelectionWheelStatics;
import Vino.Camera.Capabilities.CameraTags;

class UEmoteCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Emotes");
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter OwningPlayer;

	UPROPERTY(Category = "Component")
	TSubclassOf<UEmoteComponent> EmoteComponentClass;
    UEmoteComponent EmoteComponent;

	UPROPERTY(Category = "Widget")
	TSubclassOf<USelectionWheelWidget> WidgetClass;
	USelectionWheelWidget Widget;

	TArray<UEmoteDataAsset> Emotes;
	int SelectedIndex;
	
    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams params)
    {
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);

		if (EmoteComponentClass.IsValid() && Owner.GetComponent(UEmoteComponent::StaticClass()) == nullptr)
			EmoteComponent = Cast<UEmoteComponent>(Owner.CreateComponent(EmoteComponentClass));
		else
			EmoteComponent = UEmoteComponent::GetOrCreate(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (WasActionStarted(ActionNames::FindOtherPlayer))
            return EHazeNetworkActivation::ActivateLocal; 

        return EHazeNetworkActivation::DontActivate;
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (WasActionStopped(ActionNames::FindOtherPlayer))
            return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
    
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//OwningPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
		OwningPlayer.BlockCapabilities(CameraTags::Control, this);

		Widget = Cast<USelectionWheelWidget>(OwningPlayer.AddWidgetToHUDSlot(n"SelectionWheel", WidgetClass));

		Emotes = EmoteComponent.Emotes;

		for(int i=0; i<Emotes.Num(); ++i)
		{
			FSelectionWheelSegmentData Data;
			Data.Icon = Emotes[i].Icon;
			Data.Description = FText::FromString("Hello: " + i);

			Widget.AddSegment(Data);
		}

		Widget.SelectedIndex = 0;
		SelectedIndex = -1;
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//OwningPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);
		//

		if (Emotes[SelectedIndex].MaysAnimation != nullptr)			
			OwningPlayer.PlayEventAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Emotes[SelectedIndex].MaysAnimation);

		
		OwningPlayer.UnblockCapabilities(CameraTags::Control, this);

		Widget.PlaySelectAnimationAndRemove(Widget.SelectedIndex);
		Widget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Input = GetAttributeVector(AttributeVectorNames::RightStickRaw);
		
		if (Input.SizeSquared() > 0.05f)
		{
			SelectedIndex = GetSelectionWheelIndexFromCoordinates(Emotes.Num(), Input.X, Input.Y);
			Widget.SelectedIndex = SelectedIndex;
		}
		else
		{
			Widget.SelectedIndex = -1;
		}
		Print("Emote - SelectedIndex: " + SelectedIndex);
	}


	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }
}
