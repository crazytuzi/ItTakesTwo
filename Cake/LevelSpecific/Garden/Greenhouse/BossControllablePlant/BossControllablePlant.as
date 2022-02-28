import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantPlayerComponent;
import Cake.LevelSpecific.Garden.Greenhouse.BossRoomSubmersibleSoil;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.ControlPlantWidget;

UCLASS(Abstract)
class ABossControllablePlant : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ButtonMashAttachPoint;

	UPROPERTY()
	ABossRoomSubmersibleSoil SoilPatch;

	UPROPERTY(Category="TEMPORARY")
	bool IsRightPlant = true;

	UPROPERTY(Category="TEMPORARY")
	bool UseButtonMash = true;

	UPROPERTY()
	bool bBeingControlled = false;

	UPROPERTY()
	bool bIsAlive = false;

	AHazePlayerCharacter ControllingPlayer;
	UBossControllablePlantPlayerComponent BossPlantsComp;

	UPROPERTY(Category="Widget")
	TSubclassOf<UControlPlantWidget> ProgressWidgetClass;

	UPROPERTY(Category="Widget")
	TSubclassOf<UHazeInputButton> ProgressInputWidgetClass;

	UPROPERTY(DefaultComponent, Category="Button Mash")
	UHazeSmoothSyncFloatComponent SyncedButtonMashProgress;
	
	UPROPERTY(Category="Button Mash")
	float CurrentMashProgress = 0.0f;
	UPROPERTY(Category="Button Mash")
	float ButtonMashAddSpeed = 0.1f;
	UPROPERTY(Category="Button Mash")
	float ButtonMashConstantDecreaseSpeed = 0.01f;
	UPROPERTY(Category="Button Mash")
	float ButtonMashFreeDecreaseSpeed = 1.0f;
	UPROPERTY(Category="Button Mash")
	float ButtonMashFreeDecreaseTime = 0.15f;
	UPROPERTY(Category="Button Mash")
	float ButtonMashCooldown = 0.2f;
	UPROPERTY(Category="Button Mash")
	bool bFullyButtonMashed = false;

	UPROPERTY()
	FVector2D StickInput = FVector2D::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SoilPatch.OnPlayerSubmergedInBossSoil.AddUFunction(this, n"ActivateArm");
		SoilPatch.OnPlayerLeftBossSoil.AddUFunction(this, n"DeactivateArm");
	}

	UFUNCTION()
	void SetIsAlive(bool IsAlive)
	{
		bIsAlive = IsAlive;
	}


	UFUNCTION()
	void DeactivateArm()
	{
		bBeingControlled = false;
		ControllingPlayer = nullptr;
		BossPlantsComp = nullptr;
	}

	UFUNCTION()
	void ActivateArm(AHazePlayerCharacter Player)
	{
		bBeingControlled = true;
		ControllingPlayer = Player;
		BossPlantsComp = UBossControllablePlantPlayerComponent::Get(ControllingPlayer);
	}

	void AddProgress(float NewProgress, float Decreasement)
	{
		CurrentMashProgress += NewProgress;
		CurrentMashProgress -= Decreasement;
		CurrentMashProgress = FMath::Clamp(CurrentMashProgress, 0.0f, 1.0f);
		SyncedButtonMashProgress.Value = CurrentMashProgress;

		if(CurrentMashProgress == 1.0f)
		 	bFullyButtonMashed = true;
		else
			bFullyButtonMashed = false;
	}

}