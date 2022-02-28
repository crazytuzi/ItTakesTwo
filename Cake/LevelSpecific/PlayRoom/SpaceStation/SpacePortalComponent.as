import Effects.PostProcess.PostProcessing;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortal.SpacePortalScreenSpaceEffectActor;
import Vino.PlayerMarker.PlayerMarkerComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Cake.Orientation.OtherPlayerIndicatorSettings;

UCLASS(Abstract)
class USpacePortalComponent : UActorComponent
{
	UPROPERTY(NotVisible)
	AHazePlayerCharacter Player;

	UPROPERTY(Category = "Tunnel")
	UAnimSequence MayPortalMH;

	UPROPERTY(Category = "Tunnel")
	UAnimSequence CodyPortalMH;

	UPROPERTY(Category = "Exit")
	UAnimSequence MayExitAnim;

	UPROPERTY(Category = "Exit")
	UAnimSequence CodyExitAnim;

	UPROPERTY(Category = "Tunnel")
	TSubclassOf<UCameraShakeBase> TunnelCameraShake;

	UPROPERTY(Category = "Walkin")
	UAnimSequence MayWalkin;

	UPROPERTY(Category = "Walkin")
	UAnimSequence CodyWalkin;

	UPROPERTY()
	USpacestationVOBank VOBank;

	UPROPERTY()
	UForceFeedbackEffect EnterRumble;

	UPROPERTY()
	UForceFeedbackEffect ExitRumble;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASpacePortalScreenSpaceEffectActor> EffectActorClass;
	ASpacePortalScreenSpaceEffectActor EffectActor;

	ESpaceStation CurrentStation = ESpaceStation::Hub;
	ESpaceStation TargetStation = ESpaceStation::Hub;

	bool bOutlineEnabled = true;
	bool bInTunnel = false;
	bool bFindOtherPlayerBlocked = false;

	FVector LastHubPortalLocation = FVector::ZeroVector;

	UPlayerMarkerComponent OwnPlayerMarker;
	UPlayerMarkerComponent OtherPlayerMarker;

	bool bPlayExitBark = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		
		EffectActor = Cast<ASpacePortalScreenSpaceEffectActor>(SpawnActor(EffectActorClass, Level = Owner.GetLevel()));
		EffectActor.TargetPlayer = Player;
		EffectActor.EnterEffectComp.SetRenderedForPlayer(Player.OtherPlayer, false);
		EffectActor.ExitEffectComp.SetRenderedForPlayer(Player.OtherPlayer, false);

		OwnPlayerMarker = UPlayerMarkerComponent::Get(Player);
		OtherPlayerMarker = UPlayerMarkerComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (EffectActor != nullptr)
		{
			EffectActor.DestroyActor();
			EffectActor = nullptr;
		}

		if (!bOutlineEnabled)
		{
			Player.OtherPlayer.Mesh.SetRenderedForPlayer(Player, true);
			Player.EnableOutlineByInstigator(this);
		}

		if (bFindOtherPlayerBlocked)
		{
			bFindOtherPlayerBlocked = false;
			Player.UnblockCapabilities(n"FindOtherPlayer", this);
		}

		Player.ClearSettingsByInstigator(this);
		OwnPlayerMarker.ClearForceEnabled(OwnPlayerMarker);
		OwnPlayerMarker.ClearForceDisabled(OwnPlayerMarker);
		OtherPlayerMarker.ClearForceEnabled(OtherPlayerMarker);
		OtherPlayerMarker.ClearForceDisabled(OtherPlayerMarker);
	}

	void EnterPortal(ESpaceStation Station, FVector PortalLocation)
	{
		USpacePortalComponent OtherPlayerPortalComp = USpacePortalComponent::Get(Player.OtherPlayer);
		if (OtherPlayerPortalComp == nullptr)
			return;

		if (CurrentStation == ESpaceStation::Hub)
		{
			LastHubPortalLocation = PortalLocation + FVector(0.f, 0.f, 400.f);
			UOtherPlayerIndicatorSettings::SetbOverridePlayerLocation(Player.OtherPlayer, true, this, EHazeSettingsPriority::Gameplay);
			UOtherPlayerIndicatorSettings::SetOverrideLocation(Player.OtherPlayer, LastHubPortalLocation, this, EHazeSettingsPriority::Gameplay);
		}
		else
		{
			if (OtherPlayerPortalComp.CurrentStation != ESpaceStation::Hub)
			{
				OtherPlayerPortalComp.BlockFindOtherPlayer();
				OtherPlayerMarker.SetForceDisabled(OtherPlayerMarker);
			}
		}

		bInTunnel = true;
		CurrentStation = Station;

		DisableVisibilityForOtherPlayer();
		OtherPlayerPortalComp.DisableVisibilityForOtherPlayer();

		BlockFindOtherPlayer();

		// Never show any player markers when in portal
		OwnPlayerMarker.SetForceDisabled(OwnPlayerMarker);
	}

	void ExitPortal()
	{
		bInTunnel = false;

		USpacePortalComponent OtherPlayerPortalComp = USpacePortalComponent::Get(Player.OtherPlayer);
		if (OtherPlayerPortalComp == nullptr)
			return;

		if (CurrentStation == ESpaceStation::Hub)
		{
			UnblockFindOtherPlayer();
		}
			
		if (CurrentStation == OtherPlayerPortalComp.CurrentStation)
		{
			if (OtherPlayerPortalComp.bInTunnel)
				return;

			EnableVisibilityForOtherPlayer();
			OtherPlayerPortalComp.EnableVisibilityForOtherPlayer();
			OtherPlayerMarker.ClearForceDisabled(OtherPlayerMarker);
			OwnPlayerMarker.ClearForceDisabled(OwnPlayerMarker);
		}
		else if (CurrentStation == ESpaceStation::Hub)
		{
			FVector Loc = OtherPlayerPortalComp.LastHubPortalLocation;
			UOtherPlayerIndicatorSettings::SetbOverridePlayerLocation(Player, true, this, EHazeSettingsPriority::Gameplay);
			UOtherPlayerIndicatorSettings::SetOverrideLocation(Player, Loc, this, EHazeSettingsPriority::Gameplay);
			OwnPlayerMarker.ClearForceDisabled(OwnPlayerMarker);
		}

		// Allow marker to show for other player when back out again
	}

	void EnableVisibilityForOtherPlayer()
	{
		if (!bOutlineEnabled)
		{
			bOutlineEnabled = true;
			Player.EnableOutlineByInstigator(this);
			Player.OtherPlayer.Mesh.SetRenderedForPlayer(Player, true);
			UnblockFindOtherPlayer();

			Player.OtherPlayer.ClearSettingsByInstigator(this);
			Player.ClearSettingsByInstigator(this);

			// OtherPlayerMarker.ClearForceEnabled(this);
		}
	}

	void DisableVisibilityForOtherPlayer()
	{
		if (bOutlineEnabled)
		{
			bOutlineEnabled = false;
			Player.DisableOutlineByInstigator(this);
			Player.OtherPlayer.Mesh.SetRenderedForPlayer(Player, false);

			// OtherPlayerMarker.SetForceEnabled(this);
		}
	}

	void BlockFindOtherPlayer()
	{
		if (bFindOtherPlayerBlocked)
			return;

		bFindOtherPlayerBlocked = true;
		Player.BlockCapabilities(n"FindOtherPlayer", this);
	}

	void UnblockFindOtherPlayer()
	{
		if (!bFindOtherPlayerBlocked)
			return;

		bFindOtherPlayerBlocked = false;
		Player.UnblockCapabilities(n"FindOtherPlayer", this);
	}
}

enum ESpaceStation
{
	Hub,
	PlasmaBall,
	Planets,
	SideScroller,
	LaunchBoard,
	TractorBeam,
	Conductor,
	LowGravity,
	LaserGame
}

UFUNCTION()
void SetSpaceStationCurrentStation(AHazePlayerCharacter Player, ESpaceStation Station, AActor HubPortal)
{
	USpacePortalComponent PortalComp = USpacePortalComponent::Get(Player);
	if (PortalComp == nullptr)
		return;

	PortalComp.CurrentStation = Station;
	if (HubPortal != nullptr)
	{
		PortalComp.LastHubPortalLocation = HubPortal.ActorLocation + FVector(0.f, 0.f, 400.f);
	}
}