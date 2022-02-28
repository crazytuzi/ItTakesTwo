import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;

import void ActivateSubmersibleSoilComponent(USubmersibleSoilComponent, AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";

struct FPlayerSubmergedInSoilInfo
{
	AHazePlayerCharacter Player;
	AControllablePlant ControlledPlant;
	USubmersibleSoilComponent Soil;

	void BroadcastEnter()
	{
		if(Soil != nullptr)
		{
			Soil.OnPlayerSubmergedInSoil.Broadcast(this);
			Soil.OnPlayerEntered.ExecuteIfBound(this);
		}		
	}

	void BroadcastExit()
	{
		if(Soil != nullptr)
		{
			Soil.OnPlayerExited.ExecuteIfBound(this);
		}	
	}
}

event void FOnPlayerSubmergedInSoil(const FPlayerSubmergedInSoilInfo& PlayerSubmergedInSoilInfo);
event void FOnPlayerEnterExitSoil(AHazePlayerCharacter ExitingPlayer);
delegate void FOnPlayerChangedState(const FPlayerSubmergedInSoilInfo& PlayerSubmergedInSoilInfo);

UCLASS(hidecategories = "Activation AssetUserData")
class USubmersibleSoilComponent : UActorComponent
{	
	UPROPERTY(Category = "Events")
	FOnPlayerSubmergedInSoil OnPlayerSubmergedInSoil;

	UPROPERTY(Category = "Events")
	FOnPlayerEnterExitSoil OnPlayerEnterSoil;

	UPROPERTY(Category = "Events")
	FOnPlayerEnterExitSoil OnPlayerExitSoil;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnGroundPoundHitEvent;

	UPROPERTY(Category = "Plants", EditDefaultsOnly)
	TSubclassOf<AControllablePlant> PlantClass;

	FOnPlayerChangedState OnPlayerEntered;
	FOnPlayerChangedState OnPlayerExited;

	UPrimitiveComponent SoilMesh;

	bool bCanEnterSoil = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorGroundPoundedDelegate GroundPoundedDelegate;
        GroundPoundedDelegate.BindUFunction(this, n"GroundPounded");
        BindOnActorGroundPounded(GetOwner(), GroundPoundedDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void GroundPounded(AHazePlayerCharacter Player)
	{
		if(!bCanEnterSoil)
			return;

		ActivateSubmersibleSoilComponent(this, Player);
		Player.PlayerHazeAkComp.HazePostEvent(OnGroundPoundHitEvent);
	}
}
