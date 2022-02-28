import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagPlayerComp;

class USpiderTagPlayerItTimerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SpiderTagPlayerItTimerCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"TagMinigame";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
 
	USpiderTagPlayerComp PlayerComp;

	float NewLightTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USpiderTagPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.SpiderTagPlayerState == ESpiderTagPlayerState::InPlay && PlayerComp.bWeAreIt)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.SpiderTagPlayerState != ESpiderTagPlayerState::InPlay || !PlayerComp.bWeAreIt)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.BombMesh = Cast<ABombMesh>(SpawnActor(PlayerComp.BombMeshClass)); 
		PlayerComp.BombMesh.AttachToComponent(Player.Mesh, n"RideSocket");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//Spawn puff of smoke for bomb
		PlayerComp.BombMesh.BombDisappears();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (PlayerComp.BombMesh != nullptr)
			PlayerComp.BombMesh.BombDisappears();
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (PlayerComp.bWeAreIt)
		{
			PlayerComp.TimeAsIt -= DeltaTime;

			float LightMultiplier = PlayerComp.TimeAsIt / 20.f; 
			// PrintToScreen("" + Owner.Name + " - TimeAsIt: " + PlayerComp.TimeAsIt);

			System::DrawDebugSphere(Player.ActorLocation, 400.f);

			if (NewLightTime <= System::GameTimeInSeconds)
			{
				NewLightTime = System::GameTimeInSeconds + PlayerComp.LightRate * LightMultiplier;
				
				// PlayerComp.CountDownSetter();

				PlayerComp.BombMesh.ActivateLight(PlayerComp.LightRate * (LightMultiplier * 0.6f));
			}
			
			if (PlayerComp.TimeAsIt <= 0.f)
			{
				PlayerComp.SpiderTagPlayerState = ESpiderTagPlayerState::Exploding;
			} 
		}

		
	}
}