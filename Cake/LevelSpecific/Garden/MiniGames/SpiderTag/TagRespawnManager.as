import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagPlayerComp;

event void FRespawnActivated(AHazePlayerCharacter Player);

class ATagRespawnManager : AHazeActor
{
	FRespawnActivated OnRespawnActivatedEvent;

	TPerPlayer<AHazePlayerCharacter> Players;

	TPerPlayer<float> ZDistances;

	UPROPERTY(meta = (MakeEditWidget))
	FVector RespawnLoc;

	FVector WorldLoc;

	float ZStart;

	float ZThreshold = -350.f;

	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Players[0] = Game::May;
		Players[1] = Game::Cody;
	
		ZStart = ActorLocation.Z;

		WorldLoc = RootComponent.RelativeTransform.TransformPosition(RespawnLoc);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bIsActive)
			return;

		if (Players[0] == nullptr || Players[1] == nullptr)
			return;

		ZDistances[0] = Players[0].ActorLocation.Z - ZStart;
		ZDistances[1] = Players[1].ActorLocation.Z - ZStart;

		if (HasControl())
		{
			if (ZDistances[0] <= ZThreshold)
				RespawnPlayer(Players[0]);

			if (ZDistances[1] <= ZThreshold)
				RespawnPlayer(Players[1]);
		}
	}

	UFUNCTION(NetFunction)
	void RespawnPlayer(AHazePlayerCharacter Player)
	{
		Print ("Respawned Player");
		
		Player.TeleportActor(WorldLoc, Player.ActorRotation);

		USpiderTagPlayerComp PlayerComp = USpiderTagPlayerComp::Get(Player); 

		if (PlayerComp == nullptr)
			return;

		if (!PlayerComp.bWeAreIt)
			OnRespawnActivatedEvent.Broadcast(Player);
	}
}