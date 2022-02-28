import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossDeathComponent;
class AClockworkLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	UHazeCapabilitySheet CodySheet = Asset("/Game/Blueprints/LevelSpecific/Clockwork/CapabilitySheets/TimeAbility_SHEET.TimeAbility_SHEET");

	UPROPERTY()
	UHazeCapabilitySheet MaySheet = Asset("/Game/Blueprints/LevelSpecific/Clockwork/CapabilitySheets/SequenceAbility_SHEET.SequenceAbility_SHEET");

	UPROPERTY()
	UHazeCapabilitySheet DeathSheet = Asset("/Game/Blueprints/LevelSpecific/Clockwork/Actors/LastBoss/CapabilitySheets/DA_ClockworkLastBossDeathSheet.DA_ClockworkLastBossDeathSheet");

	UPROPERTY()
	UHazeCapabilitySheet WalkTogetherSheet = Asset("/Game/Blueprints/LevelSpecific/Clockwork/Actors/LastBoss/CapabilitySheets/DA_ClockworkLastBossWalkTogetherSheet.DA_ClockworkLastBossWalkTogetherSheet");

	UPROPERTY()
	UHazeCapabilitySheet JumpToGrindSheet = Asset("/Game/Blueprints/LevelSpecific/Clockwork/Actors/LastBoss/CapabilitySheets/DA_ClockworkLastBossJumpToGrindSheet.DA_ClockworkLastBossJumpToGrindSheet");

	UFUNCTION()
	void InitializeClockwork(bool bAddSheets)
	{
		if (bAddSheets)
		{
			if (MaySheet != nullptr)
			{
				Game::GetMay().AddCapabilitySheet(MaySheet, EHazeCapabilitySheetPriority::Normal, this);
			}

			if (CodySheet != nullptr)
			{
				Game::GetCody().AddCapabilitySheet(CodySheet, EHazeCapabilitySheetPriority::Normal, this);
			}
		}
	}

	UFUNCTION()
	void SetOutlineDisabled(bool bDisabled)
	{
		for (auto Player : Game::GetPlayers())
		{
			if (bDisabled)
				Player.DisableOutlineByInstigator(this);
			else
				Player.EnableOutlineByInstigator(this);
		}
	}

	UFUNCTION()
	void SetCodyFullscreen()
	{
		// Don't think that this function is used? 
		//Game::GetCody().SetViewSize(EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);	
	}

	UFUNCTION()
	void SetClockBossDeathCapabilityActive(bool bActive, bool bAddSheet, AHazePlayerCharacter Player)
	{
		if (bAddSheet)
			Player.AddCapabilitySheet(DeathSheet, EHazeCapabilitySheetPriority::Normal, this);

		EHazeActionState State = bActive ? EHazeActionState::Active : EHazeActionState::Inactive;  
		Player.SetCapabilityActionState(n"ClockDeath", State);
	}

	UFUNCTION()
	void SetNewFallHeightToDeath(float NewFallHeight, AHazePlayerCharacter Player)
	{
		UClockworkLastBossDeathComponent Comp = Cast<UClockworkLastBossDeathComponent>(Player.GetComponentByClass(UClockworkLastBossDeathComponent::StaticClass()));
		if (Comp != nullptr)
			Comp.SetNewFallHeightToDeath(NewFallHeight);
	}

	UFUNCTION()
	void AddWalkTogetherSheet()
	{
		Game::GetCody().AddCapabilitySheet(WalkTogetherSheet, EHazeCapabilitySheetPriority::Normal, this);
		Game::GetMay().AddCapabilitySheet(WalkTogetherSheet, EHazeCapabilitySheetPriority::Normal, this);
	}

	UFUNCTION()
	void AddJumpToGrindSheet()
	{
		Game::GetCody().AddCapabilitySheet(JumpToGrindSheet, EHazeCapabilitySheetPriority::Normal, this);
		Game::GetMay().AddCapabilitySheet(JumpToGrindSheet, EHazeCapabilitySheetPriority::Normal, this);
	}

	UFUNCTION(BlueprintCallable)
	void AddClocktownVOManager(TSubclassOf<UHazeCapability> ClocktownerVOCapability)
	{
		UClass ClocktownVOClass = ClocktownerVOCapability.Get();
		if(ClocktownVOClass != nullptr)
			Game::GetMay().AddCapability(ClocktownVOClass);
	}
}