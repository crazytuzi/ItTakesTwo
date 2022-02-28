import Vino.StickControlledLever.StickControlledLever;
import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonTimedPlatform;
import Vino.PressurePlate.PressurePlate;

event void FBothPlatesPressed(AHazePlayerCharacter LeftPlayer, AHazePlayerCharacter RightPlayer);

class AHopscotchDungeonTimedPlatformsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	AStickControlledLever LeftLever;

	UPROPERTY()
	AStickControlledLever RightLever;

	UPROPERTY()
	AStickControlledLever LeftDoorOpenLever;

	UPROPERTY()
	AStickControlledLever RightDoorOpenLever;

	UPROPERTY()
	AStaticMeshActor MouseLamp;

	UPROPERTY()
	TArray<AHopscotchDungeonTimedPlatform> PlatformArray;

	UPROPERTY()
	FBothPlatesPressed BothPressurePlatesPressedEvent;

	UPROPERTY()
	FLinearColor LitMouseLampColor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftLever.LeverValueChanged.AddUFunction(this, n"LeftLeverValueChanged");
		RightLever.LeverValueChanged.AddUFunction(this, n"RightLeverValueChanged");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION(CallInEditor)
	void SetPlatformArray()
	{
		GetAllActorsOfClass(PlatformArray);
	}

	UFUNCTION()
	void LeftLeverValueChanged(float Value)
	{
		for(auto Platform : PlatformArray)
		{
			if (Platform.bIsYellow)
				Platform.UpdatePosition(Value);
		}
	}

	UFUNCTION()
	void RightLeverValueChanged(float Value)
	{
		for(auto Platform : PlatformArray)
		{
			if (!Platform.bIsYellow)
				Platform.UpdatePosition(Value);
		}
	}

	// this is called from BP when both Plates are pressed
	UFUNCTION(NetFunction)
	void NetBothPlatesPressed(AHazePlayerCharacter LeftPlayer, AHazePlayerCharacter RightPlayer)
	{
		BothPressurePlatesPressedEvent.Broadcast(LeftPlayer, RightPlayer);
	}

	UFUNCTION(NetFunction)
	void NetLightMouseLamp()
	{
		MouseLamp.StaticMeshComponent.SetColorParameterValueOnMaterialIndex(0, n"Color", LitMouseLampColor);
	}
}