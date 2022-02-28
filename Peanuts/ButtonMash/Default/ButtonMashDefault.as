import Peanuts.ButtonMash.ButtonMashComponent;
import Peanuts.ButtonMash.ButtonMashWidget;
import Peanuts.ButtonMash.ButtonMashHandleBase;
import Peanuts.ButtonMash.ButtonMashStatics;

class UButtonMashDefaultHandle : UButtonMashHandleBase
{
	// Attachment data
	UPROPERTY()
	USceneComponent AttachTo;

	UPROPERTY()
	FName AttachSocket;

	UPROPERTY()
	FVector AttachLocalOffset;
}

class UButtonMashDefaultCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ButtonMashTags::ButtonMash);

	AHazePlayerCharacter Player;

	UButtonMashComponent MashComponent;
	UButtonMashWidget Widget;

	UButtonMashDefaultHandle Handle;

	UPROPERTY()
	TSubclassOf<UButtonMashWidget> WidgetClass;

	float ControlSyncTime = 0.f;
	float RemotePulseTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParms)
	{
		MashComponent = UButtonMashComponent::GetOrCreate(Owner);

		// Get player
		Player = Cast<AHazePlayerCharacter>(Owner);
		devEnsure(Player != nullptr, "You can't put this capability on a non-player. Use the StartButtonMashDefault- static functions.");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{ 
		if (MashComponent.CurrentButtonMash != nullptr &&
			MashComponent.CurrentButtonMash.IsA(UButtonMashDefaultHandle::StaticClass()))
			return EHazeNetworkActivation::ActivateLocal;


		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MashComponent.CurrentButtonMash == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Handle = Cast<UButtonMashDefaultHandle>(MashComponent.CurrentButtonMash);
		Widget = Cast<UButtonMashWidget>(Player.AddWidget(WidgetClass));

		Widget.AttachWidgetToComponent(Handle.AttachTo, Handle.AttachSocket);
		Widget.SetWidgetRelativeAttachOffset(Handle.AttachLocalOffset);
		Widget.SetWidgetShowInFullscreen(true);

		if (Handle.bIsExclusive)
			Widget.MakeExclusive();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Handle = nullptr;
		Widget.FadeOut();
		Widget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "Mash Rate: " + MashComponent.CurrentButtonMash.MashRateControlSide;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			// Sync over network if specified
			if (Handle.bSyncOverNetwork && Network::IsNetworked())
			{
				if (Time::GameTimeSeconds > ControlSyncTime)
				{
					NetSetControlData(Handle.MashRateControlSide);
					ControlSyncTime = Time::GameTimeSeconds + 0.5f;
				}
			}

			if (WasActionStarted(ActionNames::ButtonMash))
			{
				MashComponent.DoMashPulse();
				Widget.Pulse();
			}
		}
		else
		{
			if (Handle.MashRateRemoteSide > SMALL_NUMBER)
			{
				RemotePulseTimer += DeltaTime;
				if (RemotePulseTimer > 1.f / Handle.MashRateRemoteSide)
				{
					Widget.Pulse();
					RemotePulseTimer = 0.f;
				}
			}
		}
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSetControlData(float MashRate)
	{
		if (Handle != nullptr)
			Handle.MashRateRemoteSide = MashRate;
	}
}

UFUNCTION(Category = "ButtonMash|Default", meta = (ReturnDisplayName = Handle))
UButtonMashDefaultHandle StartButtonMashDefaultAttachToComponent(
	AHazePlayerCharacter Player,
	USceneComponent AttachComponent,
	FName AttachSocket,
	FVector AttachLocalOffset
)
{
	// Create handle
	UButtonMashDefaultHandle Handle = 
		Cast<UButtonMashDefaultHandle>(
			CreateButtonMashHandle(
				Player,
				UButtonMashDefaultHandle::StaticClass()
			)
		);

	// Set attachment stuff
	UButtonMashComponent MashComponent = UButtonMashComponent::Get(Player);
	Handle.PushCapability(MashComponent.DefaultCapabilityClass);
	Handle.AttachTo = AttachComponent;
	Handle.AttachSocket = AttachSocket;
	Handle.AttachLocalOffset = AttachLocalOffset;

	// Start it up!
	StartButtonMashInternal(Handle);
	return Handle;
}

UFUNCTION(Category = "ButtonMash|Default", meta = (ReturnDisplayName = Handle))
UButtonMashDefaultHandle StartButtonMashDefaultAttachToActor(
	AHazePlayerCharacter Player,
	AActor AttachActor,
	FVector AttachLocalOffset
)
{
	// Attach to root component of actor
	return StartButtonMashDefaultAttachToComponent(
		Player,
		AttachActor.GetRootComponent(),
		NAME_None,
		AttachLocalOffset
	);
}