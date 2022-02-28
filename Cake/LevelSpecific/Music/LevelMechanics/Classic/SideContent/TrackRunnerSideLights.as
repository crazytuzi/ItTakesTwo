import Peanuts.Triggers.PlayerTrigger;

class ATrackRunnerSideLights : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	APlayerTrigger Trigger;
	UPROPERTY()
	ESideLightsPlayer PlayerEnum;
	AHazePlayerCharacter MyPlayer;
	UPROPERTY()
	FLinearColor EmissiveColor = FLinearColor(0,0.038568, 20, 0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterTrigger");
		Trigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeaverigger");
		if(PlayerEnum == ESideLightsPlayer::May)
			MyPlayer = Game::GetMay();
		if(PlayerEnum == ESideLightsPlayer::Cody)
			MyPlayer = Game::GetCody();

		Mesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", FLinearColor(0,0,0,0));
	}

	UFUNCTION()
	void OnPlayerEnterTrigger(AHazePlayerCharacter Player)
	{
		if(Player == MyPlayer)
		{
			Mesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", FLinearColor(EmissiveColor));
		}
	}

	UFUNCTION()
	void OnPlayerLeaverigger(AHazePlayerCharacter Player)
	{
		if(Player == MyPlayer)
		{
			Mesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", FLinearColor(0,0,0,0));
		}
	}
}

enum ESideLightsPlayer
{
	May,
	Cody,
}
