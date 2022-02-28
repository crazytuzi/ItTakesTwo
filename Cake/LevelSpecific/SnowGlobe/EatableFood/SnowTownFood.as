import Vino.Interactions.InteractionComponent;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class ASnowTownFood : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PlateMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(Category = "Setup")
	UFoghornVOBankDataAssetBase VOLevelBank;

	UPROPERTY(Category = "Animations")
	UAnimSequence EatingAnimationsCody1;

	UPROPERTY(Category = "Animations")
	UAnimSequence EatingAnimationsCody2;

	UPROPERTY(Category = "Animations")
	UAnimSequence EatingAnimationsMay1;

	UPROPERTY(Category = "Animations")
	UAnimSequence EatingAnimationsMay2;

	UPROPERTY(Category = "Capability")
	TSubclassOf<UHazeCapability> PlayerCapability;

	UPROPERTY(Category = "Mesh")
	TArray<AHazeProp> MeshArray;

	int Count;

	TPerPlayer<bool> bIsMirror;

	float VOTimer;
	float DefaultVOTimer = 1.2f;
	bool bPlayedVO;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnActivated.AddUFunction(this, n"OnPlayerEat");

		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"InteractionCondition");
		InteractComp.AddTriggerCondition(n"Grounded", Condition);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bPlayedVO)
		{
			VOTimer -= DeltaTime;

			if (VOTimer <= 0.f)
				bPlayedVO = false;
		}
	}

	UFUNCTION()
	bool InteractionCondition(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		if(Player.MovementState.GroundedState != EHazeGroundedState::Grounded)
			return false;
		else
			return true;
	}

	UFUNCTION()
	void OnPlayerEat(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.AddCapability(PlayerCapability);
		Player.SetCapabilityAttributeObject(n"FoodPlate", this);
		InteractComp.Disable(n"EatingFood");

		if (Player.IsMay())
		{
			bIsMirror[0] = !bIsMirror[0];

			if (bIsMirror[0])
				Player.SetCapabilityAttributeValue(n"IsMirror", 1);
			else
				Player.SetCapabilityAttributeValue(n"IsMirror", 0);

			if (VOTimer <= 0.f)
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowGlobeTownEatingFoodMay");
		}
		else
		{
			bIsMirror[1] = !bIsMirror[1];

			if (bIsMirror[1])
				Player.SetCapabilityAttributeValue(n"IsMirror", 1);
			else
				Player.SetCapabilityAttributeValue(n"IsMirror", 0);			

			if (VOTimer <= 0.f)
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowGlobeTownEatingFoodCody");
		}
		
		if (!bPlayedVO)
		{
			bPlayedVO = true;
			VOTimer = DefaultVOTimer;
		}
	}

	UFUNCTION()
	void EnableInteraction()
	{
		InteractComp.EnableAfterFullSyncPoint(n"EatingFood");
	}

	UFUNCTION()
	void InteractionActivated()
	{
		int disabledCount = 0;
		int enabledFoodCount = 0;
		
		for (AHazeProp Food : MeshArray)
		{
			if (Food.IsActorDisabled())
			{
				disabledCount++;
			}

			if (!Food.IsActorDisabled() && enabledFoodCount == 0)
			{
				Food.DisableActor(this);
				enabledFoodCount++;
				disabledCount++;
				continue;
			}
		}

		if (disabledCount >= MeshArray.Num())
			InteractComp.Disable(n"Finished Eating");
	}

	UFUNCTION()
	void RemovePlayerCapability(AHazePlayerCharacter Player)
	{
		Player.RemoveCapability(PlayerCapability);
	}
}