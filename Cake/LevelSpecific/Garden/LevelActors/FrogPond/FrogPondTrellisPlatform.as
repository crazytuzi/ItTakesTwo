import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Cake.LevelSpecific.Garden.VOBanks.GardenFrogPondVOBank;

class AFrogPondTrellisPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	int MaterialIndexToUse = 0;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bRenderWhileDisabled = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactedComp;
	default ImpactedComp.ComponentTickEnabled = false;

	UPROPERTY(Category = "Audio")
	UGardenFrogPondVOBank VOBank;

	UMaterialInstanceDynamic DynamicMaterialInstance;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bShouldTriggerHalfWayVO = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bShouldTriggerHalfWayVO)
		{
			ImpactedComp.OnActorDownImpactedByPlayer.AddUFunction(this, n"OnDownImpactedByPlayer");
			ImpactedComp.SetComponentTickEnabled(true);
		}
	}

	void InitializePlatform()
	{
		DynamicMaterialInstance = PlatformMesh.CreateDynamicMaterialInstance(MaterialIndexToUse);
	}

	UFUNCTION()
	void OnDownImpactedByPlayer(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		if(VOBank != nullptr && Player.IsCody())
		{
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenFrogPondGreenhouseWindowHalfway");
		}
	}
}