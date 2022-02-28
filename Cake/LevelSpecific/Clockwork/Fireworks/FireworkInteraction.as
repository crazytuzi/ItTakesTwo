import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Clockwork.Fireworks.FireworksPlayerComponent;
import Cake.LevelSpecific.Clockwork.Fireworks.FireworksManager;

class AFireworkInteraction: AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompButtonLaunch;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompButtonExplode;

	UPROPERTY()
	AFireworksManager FireworkManager;

	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect ShootRumble;

	// float NewActivateTime;
	// float ActivateRate = 0.28f;

	UPROPERTY(Category = "Capability Sheet")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;

	UPROPERTY()
	AHazeCameraActor HazeCameraActor;

	UFireworksPlayerComponent PlayerComp;

	bool bLaunchDown;
	bool bExplodeDown;

	float ZStart;
	float ZDown;
	float ZOffset = 6.f;

	FHazeAcceleratedFloat AccelZLaunch;
	FHazeAcceleratedFloat AccelZExplode;

	bool bPlayedMayVO;
	bool bPlayedCodyVO;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"FireworksInteraction");
		InteractionComp.Disable(n"HelltowerLinked");
		ZStart = MeshCompButtonLaunch.RelativeLocation.Z;
		ZDown = ZStart - ZOffset;

		AccelZLaunch.SnapTo(ZStart);
		AccelZExplode.SnapTo(ZStart);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bLaunchDown)
			AccelZLaunch.AccelerateTo(ZDown, 0.25f, DeltaTime);
		else
			AccelZLaunch.AccelerateTo(ZStart, 0.25f, DeltaTime);

		if (bExplodeDown)
			AccelZExplode.AccelerateTo(ZDown, 0.25f, DeltaTime);
		else
			AccelZExplode.AccelerateTo(ZStart, 0.25f, DeltaTime);

		FVector NewLocLaunch = FVector(MeshCompButtonLaunch.RelativeLocation.X, MeshCompButtonLaunch.RelativeLocation.Y, AccelZLaunch.Value); 
		FVector NewLocExplode = FVector(MeshCompButtonExplode.RelativeLocation.X, MeshCompButtonExplode.RelativeLocation.Y, AccelZExplode.Value); 

		MeshCompButtonLaunch.SetRelativeLocation(NewLocLaunch);
		MeshCompButtonExplode.SetRelativeLocation(NewLocExplode);
	}

	UFUNCTION()
	void SetLaunchButton(bool Value)
	{
		bLaunchDown = Value;
	}

	UFUNCTION()
	void SetExplodeButton(bool Value)
	{
		bExplodeDown = Value;
	}

	UFUNCTION()
	void EnableFireworkInteraction()
	{
		InteractionComp.EnableAfterFullSyncPoint(n"HelltowerLinked");
	}
	
	UFUNCTION()
	void DisableFireworkInteraction()
	{
		InteractionComp.Disable(n"HelltowerLinked");
	}

	UFUNCTION()
	void PlayShootRumble(AHazePlayerCharacter Player)
	{
		Player.PlayForceFeedback(ShootRumble, false, true, n"Shoot");
	}

	UFUNCTION()
	void FireworksInteraction(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.AddCapabilitySheet(PlayerCapabilitySheet);
		Player.SetCapabilityAttributeObject(n"FireworkInteraction", this);
		PlayerComp = UFireworksPlayerComponent::Get(Player);
		PlayerComp.FireworkManager = FireworkManager;
		PlayerComp.HazeCameraActor = HazeCameraActor;
		PlayerComp.PlayerCancel.BindUFunction(this, n"FireworksCancel");

		InteractionComp.Disable(n"Interaction State");

		if (Player.IsMay() && !bPlayedMayVO)
		{
			bPlayedMayVO = true;
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsideHelltowerSuccessMay");
		}
		else if (Player.IsCody() && !bPlayedCodyVO)
		{
			bPlayedCodyVO = true;
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBClockworkOutsideHelltowerSuccessCody");
		}
	}

	UFUNCTION()
	void FireworksCancel(AHazePlayerCharacter Player)
	{
		Player.RemoveCapabilitySheet(PlayerCapabilitySheet);
		PlayerComp = UFireworksPlayerComponent::Get(Player);
		InteractionComp.EnableAfterFullSyncPoint(n"Interaction State");
	}
}