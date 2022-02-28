import Vino.Movement.Components.MovementComponent;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoSettings;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossPaintableGroundEffectComponent;
import Vino.Movement.Dash.CharacterDashSettings;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.GooComponent;


class BossPaintableGroudPlayerCapbility : UHazeCapability
{
	default CapabilityTags.Add(n"JoyBossFight");
	default CapabilityDebugCategory = n"JoyBossFight";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter MyPlayer;
	APaintablePlane PaintablePlane;
	bool bStandingOnGoo = false;

	const float DamageTimerConst = 0.325f;
	float DamageTimer;

	UMovementSettings StartingMovementSettings;
	float MyPlayerOrginalMoveSpeed;
	float MyPlayerCurrentMoveSpeed;
	float MyPlayerTargetMoveSpeed;

	UCharacterDashSettings StartingDashSettings;
	float MyPlayerOriginalDashStartSpeed;
	float MyPlayerCurrentDashStartSpeed;
	float MyPlayerTargetDashStartSpeed;
	float MyPlayerOriginalDashEndSpeed;
	float MyPlayerCurrentDashEndSpeed;
	float MyPlayerTargetDashEndSpeed;

	UCharacterJumpSettings StartingJumpSettings;
	float MyPlayerOriginalFloorJumpImpulse;

	const float DamageTimerJumpConst = 3.f;
	float DamageTimerJump;
	const float DamageTimerJumpResetConst = 4.f;
	float DamageTimerJumpReset;

	bool GooSettingsAlreadyApplied = false;
	bool RecentlyStoodOnGoo = false;
	bool bTomatoDashBlocked = false;
	bool bBlockedCapabilites = false;
	UBossPaintableGroundEffectComponent BossPaintableGroundDamageEffectComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MyPlayer = Cast<AHazePlayerCharacter>(Owner);	
		BossPaintableGroundDamageEffectComponent = UBossPaintableGroundEffectComponent::Get(MyPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if(MyPlayer.IsPlayerDead())
			 return EHazeNetworkActivation::DontActivate;

		if(IsActioning(n"GooActive"))
			return EHazeNetworkActivation::ActivateLocal;

		 return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MyPlayer.IsPlayerDead())
			 return EHazeNetworkDeactivation::DeactivateLocal;

		if(!IsActioning(n"GooActive"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PaintablePlane = Cast<APaintablePlane>(GetAttributeObject(n"PaintablePlane"));
		DamageTimer = DamageTimerConst;
		DamageTimerJumpReset = DamageTimerJumpResetConst;
		DamageTimerJump = DamageTimerJumpConst;

		StartingMovementSettings = UMovementSettings::GetSettings(Owner);
		MyPlayerOrginalMoveSpeed = StartingMovementSettings.MoveSpeed;
		MyPlayerCurrentMoveSpeed = MyPlayerOrginalMoveSpeed;
		MyPlayerTargetMoveSpeed = MyPlayerOrginalMoveSpeed;

		StartingDashSettings = UCharacterDashSettings::GetSettings(Owner);
		MyPlayerOriginalDashStartSpeed = StartingDashSettings.StartSpeed;
		MyPlayerCurrentDashStartSpeed = MyPlayerOriginalDashStartSpeed;
		MyPlayerTargetDashStartSpeed = MyPlayerOriginalDashStartSpeed;
		MyPlayerOriginalDashEndSpeed = StartingDashSettings.EndSpeed;
		MyPlayerCurrentDashEndSpeed = MyPlayerOriginalDashEndSpeed;
		MyPlayerTargetDashEndSpeed = MyPlayerOriginalDashEndSpeed;

		StartingJumpSettings = UCharacterJumpSettings::GetSettings(Owner);
		MyPlayerOriginalFloorJumpImpulse = StartingJumpSettings.FloorJumpImpulse;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UMovementSettings MovementSettings = Cast<UMovementSettings>(NewObject(this, UMovementSettings::StaticClass()));
		UMovementSettings::SetMoveSpeed(MyPlayer, MyPlayerOrginalMoveSpeed, this);
		UCharacterDashSettings DashSettings = Cast<UCharacterDashSettings>(NewObject(this, UCharacterDashSettings::StaticClass()));
		UCharacterDashSettings::SetStartSpeed(MyPlayer, MyPlayerOriginalDashStartSpeed, this);
		UCharacterDashSettings::SetEndSpeed(MyPlayer, MyPlayerOriginalDashEndSpeed, this);


		//UMovementSettings::ClearMoveSpeed(MyPlayer, this);
		//UCharacterDashSettings::ClearStartSpeed(MyPlayer, this);
		//UCharacterDashSettings::ClearEndSpeed(MyPlayer, this);
		//UCharacterJumpSettings::ClearFloorJumpImpulse(MyPlayer, this);
		MyPlayer.ClearSettingsByInstigator(this);
		

		UnBlockCapabilites();

		//MyPlayer.SetCapabilityAttributeObject(n"PaintablePlane", nullptr);
	}

	UFUNCTION()
	void DamagePlayer()
	{
		if(MyPlayer == Game::GetCody())
		{
			UControllablePlantsComponent CtrlPlantComponent = UControllablePlantsComponent::Get(MyPlayer);
			ATomato Tomato = Cast<ATomato>(CtrlPlantComponent.CurrentPlant);
			
			if(Tomato == nullptr)
			{
				DamageTimer = DamageTimerConst;
				DamagePlayerHealth(MyPlayer, 0.0833333333f, BossPaintableGroundDamageEffectComponent.GooDamageEffect);
			}
			else
			{
				DamageTimer = DamageTimerConst;
				DamagePlayerHealth(MyPlayer, 0.0833333333f, BossPaintableGroundDamageEffectComponent.GooDamageEffect);
			}
		}
		else
		{
			DamageTimer = DamageTimerConst;
			DamagePlayerHealth(MyPlayer, 0.0833333333f, BossPaintableGroundDamageEffectComponent.GooDamageEffect);
		}
	}

	UFUNCTION()
	void CheckIfPlayersAreOnGoo()
	{
		FVector AreaToCheck = MyPlayer.GetActorLocation();
		if(MyPlayer == Game::GetCody())
		{
			UHazeMovementComponent MovementComp = UHazeMovementComponent::Get(MyPlayer);
			UControllablePlantsComponent CtrlPlantComponent = UControllablePlantsComponent::Get(MyPlayer);
			ATomato Tomato = Cast<ATomato>(CtrlPlantComponent.CurrentPlant);
			
			if(Tomato == nullptr)
			{
				if(PaintablePlane == nullptr)
					return;

				if(PaintablePlane.QueryData(AreaToCheck).Color.B >= 0.375f && MovementComp.IsGrounded() == true)
				{
					SetIsStandingOnGoo(true);
				}
				else
				{
					SetIsStandingOnGoo(false);
				}
			}
			else
			{
				if(PaintablePlane == nullptr)
					return;
				//PrintToScreen("PaintablePlane.QueryData(AreaToCheck).Color.R " + PaintablePlane.QueryData(AreaToCheck).Color.R);
				UHazeMovementComponent TomatoMove = UHazeMovementComponent::Get(Tomato);
				if(PaintablePlane.QueryData(AreaToCheck).Color.B >= 0.375f && TomatoMove.IsGrounded() == true)
				{
					SetIsStandingOnGoo(true);
				}
				else
				{
					SetIsStandingOnGoo(false);
				}
			}
		}
		
		if(MyPlayer == Game::GetMay())
		{
			if(PaintablePlane == nullptr)
				return;

			UHazeMovementComponent MovementComp = UHazeMovementComponent::Get(MyPlayer);
			//PrintToScreen("PaintablePlane.QueryData(AreaToCheck).Color.R " + PaintablePlane.QueryData(AreaToCheck).Color.R);

			if(PaintablePlane.QueryData(AreaToCheck).Color.B >= 0.375f && MovementComp.IsGrounded() == true)
			{
				SetIsStandingOnGoo(true);
			}
			else
			{
				SetIsStandingOnGoo(false);
			}		
		}
	}

	UFUNCTION()
	void StandingOnGooSettings()
	{
		if(!HasControl())
			return;

		DamageTimer = DamageTimerConst;
		MyPlayerTargetMoveSpeed = 300;
		MyPlayerTargetDashStartSpeed = 1400;
		MyPlayerTargetDashEndSpeed = 1200;
		UCharacterJumpSettings::SetFloorJumpImpulse(MyPlayer, 1025, this);

		BlockCapabilites();
	
		if(MyPlayer == Game::GetCody())
		{
			UControllablePlantsComponent CtrlPlantComponent = UControllablePlantsComponent::Get(MyPlayer);
			ATomato Tomato = Cast<ATomato>(CtrlPlantComponent.CurrentPlant);

			if(Tomato != nullptr)
			{
				Tomato.ApplySettings(Tomato.TomatoSettingsGoo, this, EHazeSettingsPriority::Final);	
				System::SetTimer(this, n"TomatoDisableDash", 0.2f, false);

				Tomato.SetCapabilityActionState(n"AudioEnteredGoo", EHazeActionState::Active);
			}					
		}

		MyPlayer.SetCapabilityActionState(n"AudioEnteredGoo", EHazeActionState::Active);	
	}
	UFUNCTION()
	void TomatoDisableDash()
	{
	}
	UFUNCTION()
	void NotStandingOnGooSettings()
	{
		DamageTimer = DamageTimerConst;
	
		if(!HasControl())
			return;

		MyPlayerTargetMoveSpeed = MyPlayerOrginalMoveSpeed;
		MyPlayerTargetDashStartSpeed = MyPlayerOriginalDashStartSpeed;
		MyPlayerTargetDashEndSpeed = MyPlayerOriginalDashEndSpeed;
		UCharacterJumpSettings::SetFloorJumpImpulse(MyPlayer, MyPlayerOriginalFloorJumpImpulse, this);

		UnBlockCapabilites();
		
		if(MyPlayer == Game::GetCody())
		{
			UControllablePlantsComponent CtrlPlantComponent = UControllablePlantsComponent::Get(MyPlayer);
			ATomato Tomato = Cast<ATomato>(CtrlPlantComponent.CurrentPlant);

			if(Tomato != nullptr)
			{
				Tomato.ClearSettingsByInstigator(this);
				Tomato.SetCapabilityActionState(n"AudioExitedGoo", EHazeActionState::Active);
				
				if(bTomatoDashBlocked == true)
				{
					bTomatoDashBlocked = false;
				}
			}			
		}

		MyPlayer.SetCapabilityActionState(n"AudioExitedGoo", EHazeActionState::Active);
	}

	void BlockCapabilites()
	{
		if(bBlockedCapabilites == true)
			return;

		bBlockedCapabilites = true;
		MyPlayer.BlockCapabilities(MovementSystemTags::Sprint, this);
		MyPlayer.BlockCapabilities(MovementSystemTags::AirJump, this);
		MyPlayer.BlockCapabilities(n"PerfectDash", this);
		MyPlayer.BlockCapabilities(n"GroundPoundDash", this);
		MyPlayer.BlockCapabilities(n"GroundPoundJump", this);
		MyPlayer.BlockCapabilities(n"AirDash", this);
		MyPlayer.BlockCapabilities(n"GroundPound", this);
	}

	void UnBlockCapabilites()
	{
		if(bBlockedCapabilites == false)
			return;
			
		bBlockedCapabilites = false;
		MyPlayer.UnblockCapabilities(MovementSystemTags::Sprint, this);
		MyPlayer.UnblockCapabilities(MovementSystemTags::AirJump, this);  
		MyPlayer.UnblockCapabilities(n"PerfectDash", this);
		MyPlayer.UnblockCapabilities(n"GroundPoundDash", this);
		MyPlayer.UnblockCapabilities(n"GroundPoundJump", this);
		MyPlayer.UnblockCapabilities(n"AirDash", this);
		MyPlayer.UnblockCapabilities(n"GroundPound", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		//PrintToScreen("MyPlayerOrginalMoveSpeed " + MyPlayerOrginalMoveSpeed);
		//PrintToScreen("MyPlayer "+ MyPlayer + "StandingOnGoo  " + StandingOnGoo);
		//PrintToScreen(" MyPlayerCurrentMoveSpeed  "  + MyPlayerCurrentMoveSpeed);
		//PrintToScreen(" MyPlayerTargetMoveSpeed  "  + MyPlayerTargetMoveSpeed);
		//PrintToScreen(" MyPlayerCurrentDashStartSpeed  "  + MyPlayerCurrentDashStartSpeed);
		//PrintToScreen(" MyPlayerTargetDashStartSpeed  "  + MyPlayerTargetDashStartSpeed);
		//PrintToScreen(" MyPlayerCurrentDashStartSpeed  "  + MyPlayerCurrentDashStartSpeed);
		//PrintToScreen(" MyPlayerTargetDashEndSpeed  "  + MyPlayerTargetDashEndSpeed);

		CheckIfPlayersAreOnGoo();
		HumanValueChanges(DeltaTime);
	
		if(bStandingOnGoo)
		{
			DamageTimer -= DeltaTime;
			if(DamageTimer <= 0)
			{
				DamagePlayer();
				DamageTimer = DamageTimerConst;
			}
		}
	}

	void SetIsStandingOnGoo(bool bValue)
	{
		bStandingOnGoo = bValue;
		UGooComponent GooComp = UGooComponent::GetOrCreate(Owner);
		GooComp.bIsStandingInsideGoo = bValue;
	}

	UFUNCTION()
	void HumanValueChanges(float DeltaTime)
	{
		if(HasControl())
		{
			MyPlayerCurrentMoveSpeed = FMath::Lerp(MyPlayerCurrentMoveSpeed, MyPlayerTargetMoveSpeed, DeltaTime * 3);
			UMovementSettings MovementSettings = Cast<UMovementSettings>(NewObject(this, UMovementSettings::StaticClass()));
			UMovementSettings::SetMoveSpeed(MyPlayer, MyPlayerCurrentMoveSpeed, this);
			UCharacterDashSettings DashSettings = Cast<UCharacterDashSettings>(NewObject(this, UCharacterDashSettings::StaticClass()));
			MyPlayerCurrentDashEndSpeed = FMath::Lerp(MyPlayerCurrentDashEndSpeed, MyPlayerTargetDashEndSpeed, DeltaTime * 3);
			MyPlayerCurrentDashStartSpeed = FMath::Lerp(MyPlayerCurrentDashStartSpeed, MyPlayerTargetDashStartSpeed, DeltaTime * 3);
			UCharacterDashSettings::SetStartSpeed(MyPlayer, MyPlayerTargetDashStartSpeed, this);
			UCharacterDashSettings::SetEndSpeed(MyPlayer, MyPlayerTargetDashEndSpeed, this);
		}


		if(MyPlayer == Game::GetMay())
		{
			if(GooSettingsAlreadyApplied == false)
			{
				if(bStandingOnGoo)
				{
					StandingOnGooSettings();
					RecentlyStoodOnGoo = true;
					GooSettingsAlreadyApplied = true;
				}
			}
			if(RecentlyStoodOnGoo == true)
			{
				UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(MyPlayer);
				if(!MoveComp.IsGrounded())
				{
					if(HasControl())
					{
						MoveComp.Velocity -= MoveComp.Velocity * 5.f * DeltaTime;
						if(USwingingComponent::GetOrCreate(Game::May).IsSwinging())
						{
							RecentlyStoodOnGoo = false;
							GooSettingsAlreadyApplied = false;
							NotStandingOnGooSettings();
						}
					}	
					
				}
				else if(MoveComp.IsGrounded())
				{
					if(!bStandingOnGoo)
					{
						RecentlyStoodOnGoo = false;
						GooSettingsAlreadyApplied = false;
						NotStandingOnGooSettings();
					}
				}
			}
		}

		if(MyPlayer == Game::GetCody())
		{
			if(GooSettingsAlreadyApplied == false)
			{
				if(bStandingOnGoo)
				{
					StandingOnGooSettings();
					RecentlyStoodOnGoo = true;
					GooSettingsAlreadyApplied = true;
				}
			}
			if(RecentlyStoodOnGoo == true)
			{
				UControllablePlantsComponent CtrlPlantComponent = UControllablePlantsComponent::Get(MyPlayer);
				ATomato Tomato = Cast<ATomato>(CtrlPlantComponent.CurrentPlant);
			
				if(Tomato == nullptr)
				{
					UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(MyPlayer);
					if(!MoveComp.IsGrounded())
					{
						if(HasControl())
						{
							MoveComp.Velocity -= MoveComp.Velocity * 5.f * DeltaTime;

							if(USwingingComponent::GetOrCreate(Game::Cody).IsSwinging())
							{
								RecentlyStoodOnGoo = false;
								GooSettingsAlreadyApplied = false;
								NotStandingOnGooSettings();
							}
						}	
					}
					else if(MoveComp.IsGrounded())
					{
						if(!bStandingOnGoo)
						{
							RecentlyStoodOnGoo = false;
							GooSettingsAlreadyApplied = false;
							NotStandingOnGooSettings();
						}
					}
				}
				else if(!bStandingOnGoo)
				{
					RecentlyStoodOnGoo = false;
					GooSettingsAlreadyApplied = false;
					NotStandingOnGooSettings();
				}
			}
		}
	
		if(MyPlayer == Game::GetCody())
		{
			UControllablePlantsComponent CtrlPlantComponent = UControllablePlantsComponent::Get(MyPlayer);
			ATomato Tomato = Cast<ATomato>(CtrlPlantComponent.CurrentPlant);
			
			if(Tomato != nullptr)
			{
				return;
			}
		}

		//Add drag for Dashers if dash is already active when StandingInGoo == true
		if(HasControl())
		{
			if(MyPlayer.IsAnyCapabilityActive(n"FloorDash"))
			{
				if(bStandingOnGoo)
				{
					UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(MyPlayer);
					MoveComp.Velocity -= MoveComp.Velocity * 2.5f * DeltaTime;
				}
			}
			else if(MyPlayer.IsAnyCapabilityActive(n"PerfectDash"))
			{
				if(bStandingOnGoo)
				{
					UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(MyPlayer);
					MoveComp.Velocity -= MoveComp.Velocity * 5 * DeltaTime;
				}
			}
			///Drag in Air when players jump from Goo
			if(bStandingOnGoo)
			{
				UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(MyPlayer);
				if(!MoveComp.IsGrounded())
				{	
					MoveComp.Velocity -= MoveComp.Velocity * 2.5f * DeltaTime;
				}
			}
		}
	}
}