import Vino.PlayerMarker.PlayerMarkerComponent;
import Cake.Orientation.OtherPlayerIndicatorSettings;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class UPlayerMarkerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerMarker");

	default CapabilityDebugCategory = n"HUD";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerMarkerComponent PlayerMarkerComp;
	AHazePlayerCharacter OtherPlayer;
	UPlayerMarkerComponent OtherPlayerMarkerComp;
	UPlayerRespawnComponent OtherPlayerRespawnComp;

	UPlayerMarkerWidget CurrentWidget;

	UOtherPlayerIndicatorSettings Settings;
	FHazeAcceleratedFloat OverrideAttachFraction;
	FVector StartBlendLocation = FVector::ZeroVector;
	FHazeAcceleratedVector OverrideDetachedLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMarkerComp = UPlayerMarkerComponent::Get(Player);
		InitOtherPlayer();
		Settings = UOtherPlayerIndicatorSettings::GetSettings(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void InitOtherPlayer()
	{
		OtherPlayer = Player.GetOtherPlayer();
		if (OtherPlayer == nullptr)
		{
			System::SetTimer(this, n"InitOtherPlayer", 0.5f, false);
			return;
		}

		OtherPlayerRespawnComp = UPlayerRespawnComponent::Get(OtherPlayer);
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PlayerMarkerComp.WidgetClass.IsValid())
			return EHazeNetworkActivation::DontActivate;

		if ((OtherPlayer == nullptr) || (OtherPlayerRespawnComp == nullptr))
		 	return EHazeNetworkActivation::DontActivate;
		if (IsPlayerDead(OtherPlayer))
		 	return EHazeNetworkActivation::DontActivate;
		if (OtherPlayerRespawnComp.bIsRespawning)
		 	return EHazeNetworkActivation::DontActivate;

		if (PlayerMarkerComp.IsForceEnabled())
			return EHazeNetworkActivation::ActivateLocal;

		if (!PlayerMarkerComp.IsEnabled())
			return EHazeNetworkActivation::DontActivate;

		if (SceneView::IsFullScreen())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CurrentWidget == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if ((OtherPlayer == nullptr) || (OtherPlayerRespawnComp == nullptr))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (IsPlayerDead(OtherPlayer))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (OtherPlayerRespawnComp.bIsRespawning)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (PlayerMarkerComp.IsForceEnabled())
			return EHazeNetworkDeactivation::DontDeactivate;

		if (SceneView::IsFullScreen())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!PlayerMarkerComp.IsEnabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		OtherPlayerMarkerComp = UPlayerMarkerComponent::Get(Player.OtherPlayer);
		if (Settings.bOverridePlayerLocation)
		{
			OtherPlayerMarkerComp.DetachFromParent();
			OtherPlayerMarkerComp.SetWorldLocation(Settings.OverrideLocation);
			OverrideDetachedLocation.SnapTo(Settings.OverrideLocation);
		}
		else
		{
			OverrideAttachFraction.SnapTo(0.f);
			OtherPlayerMarkerComp.AttachToComponent(Player.OtherPlayer.MeshOffsetComponent);
			OtherPlayerMarkerComp.SetRelativeLocation(Settings.PlayerOffset);
		}

		CurrentWidget = Cast<UPlayerMarkerWidget>(Player.AddWidget(PlayerMarkerComp.WidgetClass));
		CurrentWidget.AttachWidgetToComponent(OtherPlayerMarkerComp);
		CurrentWidget.SetWidgetPersistent(true); // Don't remove this widget when reset
		CurrentWidget.Setup(Player);
		CurrentWidget.OtherIndicatorComp = OtherPlayerMarkerComp;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (CurrentWidget != nullptr)
		{
			CurrentWidget.bForceShow = false;
			Player.RemoveWidget(CurrentWidget);
		}

		CurrentWidget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (CurrentWidget != nullptr)
		{
			// Move other player marker component to correct location
			if (Settings.bOverridePlayerLocation)
			{
				if (OtherPlayerMarkerComp.AttachParent != nullptr)
				{
					// We've just started using override location, detach
					OverrideDetachedLocation.SnapTo(OtherPlayerMarkerComp.WorldLocation, Player.OtherPlayer.ActorVelocity);
					OtherPlayerMarkerComp.DetachFromParent();
				}
				// Accelerate in world space in case override location is changing
				OverrideDetachedLocation.AccelerateTo(Settings.OverrideLocation, Settings.OverrideBlendDuration, DeltaTime);
				OtherPlayerMarkerComp.SetWorldLocation(OverrideDetachedLocation.Value);
			}
			else
			{
				if (OtherPlayerMarkerComp.AttachParent == nullptr)
				{
					// We've just stopped using override location, attach 
					OtherPlayerMarkerComp.AttachToComponent(Player.OtherPlayer.MeshOffsetComponent, NAME_None, EAttachmentRule::KeepWorld);
					OverrideAttachFraction.SnapTo(0.f);
					StartBlendLocation = OtherPlayerMarkerComp.WorldLocation;
				}
				// Accelerate fraction to ensure we reach player (which may be moving) within given time
				OverrideAttachFraction.AccelerateTo(1.f, Settings.OverrideBlendDuration, DeltaTime);
				FVector TargetLocation = OtherPlayerMarkerComp.AttachParent.WorldLocation + OtherPlayerMarkerComp.AttachParent.WorldTransform.TransformVector(Settings.PlayerOffset);
				OtherPlayerMarkerComp.SetWorldLocation(FMath::EaseInOut(StartBlendLocation, TargetLocation, OverrideAttachFraction.Value, 3.f));
			}
		}

		CurrentWidget.bForceShow = PlayerMarkerComp.IsForceEnabled();
	}
}