import Peanuts.ButtonMash.ButtonMashComponent;
import Peanuts.ButtonMash.ButtonMashHandleBase;
import Peanuts.ButtonMash.ButtonMashStatics;

class UButtonMashProgressWidget : UHazeUserWidget
{	
	UFUNCTION(BlueprintEvent)
	void Pulse()
	{
	}

	UFUNCTION(BlueprintEvent)
	void FadeOut()
	{
		// If this is not overriden, just destroy right away
		// But preferrably, we want some sort of animation here
		Destroy();
	}

	UFUNCTION()
	void Destroy()
	{
		Player.RemoveWidget(this);
	}

	UFUNCTION(BlueprintEvent)
	void SetProgress(float Progress)
	{
	}

	UFUNCTION(BlueprintEvent)
	void MakeExclusive()
	{
	}
}

event void FOnButtonMashProgressCompleted();
class UButtonMashProgressHandle : UButtonMashHandleBase
{
	// Attachment data
	UPROPERTY()
	USceneComponent AttachTo;

	UPROPERTY()
	FName AttachSocket;

	UPROPERTY()
	FVector AttachLocalOffset;

	// Progress data
	UPROPERTY()
	float Progress = 0.f;

	UPROPERTY()
	FOnButtonMashProgressCompleted OnCompleted;

	void Reset()
	{
		Progress = 0.f;
	}
}

class UButtonMashProgressCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ButtonMashTags::ButtonMash);

	AHazePlayerCharacter Player;

	UButtonMashComponent MashComponent;
	UButtonMashProgressWidget Widget;
	UButtonMashProgressHandle Handle;

	float PreviousProgress = 0.f;

	// Network stuff
	float ControlSideProgress = 0.f;
	float ControlSideMashRate = 0.f;
	float ControlSyncTime = 0.f;
	float RemotePulseTimer = 0.f;

	UPROPERTY()
	TSubclassOf<UButtonMashProgressWidget> WidgetClass;

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
			MashComponent.CurrentButtonMash.IsA(UButtonMashProgressHandle::StaticClass()))
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
		Handle = Cast<UButtonMashProgressHandle>(MashComponent.CurrentButtonMash);

		Widget = Cast<UButtonMashProgressWidget>(Player.AddWidget(WidgetClass));

		Widget.AttachWidgetToComponent(Handle.AttachTo, Handle.AttachSocket);
		Widget.SetWidgetRelativeAttachOffset(Handle.AttachLocalOffset);
		Widget.SetWidgetShowInFullscreen(true);

		if (Handle.bIsExclusive)
			Widget.MakeExclusive();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Widget.FadeOut();
		Widget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "Mash Rate: " + Handle.MashRateControlSide;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Handle.Progress = FMath::Clamp(Handle.Progress, 0.0, 1.0);
		Widget.SetProgress(Handle.Progress);

		if (Handle.Progress >= 1.f && PreviousProgress < 1.f)
		{
			if (Handle.bSyncOverNetwork && Network::IsNetworked())
				NetControlSideCompleted();
			else
				Handle.OnCompleted.Broadcast();
		}

		// Buttonmash can potentially be blocked from its broadcast
		// If that happens, exit out immediately :)
		if (!IsActive())
			return;

		if (HasControl())
		{
			// Sync over network if specified
			if (Handle.bSyncOverNetwork && Network::IsNetworked())
			{
				if (Time::GameTimeSeconds > ControlSyncTime)
				{
					NetSetControlData(Handle.MashRateControlSide, Handle.Progress);
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
			Handle.Progress = FMath::FInterpTo(Handle.Progress, ControlSideProgress, 2.4f, DeltaTime);
			Handle.MashRateRemoteSide = FMath::FInterpTo(Handle.MashRateRemoteSide, ControlSideMashRate, 2.4f, DeltaTime);

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

		PreviousProgress = Handle.Progress;
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSetControlData(float MashRate, float Progress)
	{
		if (Handle != nullptr)
		{
			ControlSideMashRate = MashRate;
			ControlSideProgress = Progress;
			Handle.MashRateRemoteSide = MashRate;
		}
	}

	UFUNCTION(NetFunction)
	void NetControlSideCompleted()
	{
		if (Handle != nullptr)
		{
			Handle.Progress = 1.f;
			Handle.OnCompleted.Broadcast();
		}
	}
}

UFUNCTION(Category = "ButtonMash|Progress", meta = (ReturnDisplayName = Handle))
UButtonMashProgressHandle StartButtonMashProgressAttachToComponent(
	AHazePlayerCharacter Player,
	USceneComponent AttachComponent,
	FName AttachSocket,
	FVector AttachLocalOffset
)
{
	// Create handle
	UButtonMashProgressHandle Handle = 
		Cast<UButtonMashProgressHandle>(
			CreateButtonMashHandle(
				Player,
				UButtonMashProgressHandle::StaticClass()
			)
		);

	// Set attachment stuff
	UButtonMashComponent MashComponent = UButtonMashComponent::Get(Player);
	Handle.PushCapability(MashComponent.ProgressCapabilityClass);
	Handle.AttachTo = AttachComponent;
	Handle.AttachSocket = AttachSocket;
	Handle.AttachLocalOffset = AttachLocalOffset;

	// Start it up!
	StartButtonMashInternal(Handle);
	return Handle;
}

UFUNCTION(Category = "ButtonMash|Progress", meta = (ReturnDisplayName = Handle))
UButtonMashProgressHandle StartButtonMashProgressAttachToActor(
	AHazePlayerCharacter Player,
	AActor AttachActor,
	FVector AttachLocalOffset
)
{
	// Attach to root component of actor
	return StartButtonMashProgressAttachToComponent(
		Player,
		AttachActor.GetRootComponent(),
		NAME_None,
		AttachLocalOffset
	);
}