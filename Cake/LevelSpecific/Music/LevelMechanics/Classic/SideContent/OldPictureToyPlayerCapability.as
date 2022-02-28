import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.OldPictureToy;

class AOldPictureToyPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"OldPictureToy");
	default CapabilityDebugCategory = n"OldPictureToy";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter MyPlayer;
	AOldPictureToy OldPictureToy;

	float AllowInputTimer = 1.0f;
	float AllowInputTimerTemp;
	bool bAllowInput = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MyPlayer = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AOldPictureToy OldPictureToyLocal = Cast<AOldPictureToy>(GetAttributeObject(n"OldPictureToy"));

		if(MyPlayer == Game::GetCody())
		{
			if(OldPictureToyLocal.bCodyCapabilityActivate == false)
				return EHazeNetworkActivation::DontActivate;
		}
		else
		{
			if(OldPictureToyLocal.bMayCapabilityActivate == false)
				return EHazeNetworkActivation::DontActivate;
		}
		
		if(OldPictureToyLocal == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		OldPictureToy = Cast<AOldPictureToy>(GetAttributeObject(n"OldPictureToy"));
		AllowInputTimerTemp =  AllowInputTimer;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AllowInputTimerTemp =  AllowInputTimer;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(bAllowInput)
		{
			if(WasActionStarted(ActionNames::MovementJump))
			{
				if(MyPlayer.HasControl())
				{
					OldPictureToy.SwitchPicture();
					bAllowInput = false;
				}
			}
		}
		else
		{
			AllowInputTimerTemp -= DeltaTime;
			if(AllowInputTimerTemp < 0)
			{
				AllowInputTimerTemp = AllowInputTimer;
				bAllowInput = true;
			}
		}
	}
}
