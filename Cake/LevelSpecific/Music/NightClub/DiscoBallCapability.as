import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Music.NightClub.CharacterDiscoBallFeature;
import Cake.LevelSpecific.Music.NightClub.DiscoBall;
import Cake.LevelSpecific.Music.NightClub.DiscoBallMovementSettings;
import Cake.LevelSpecific.Music.NightClub.CharacterDiscoBallMovementComponent;
import Vino.Movement.Dash.CharacterDashSettings;

settings DiscoBallDashSettings for UCharacterDashSettings
{
    DiscoBallDashSettings.StartSpeed = 1125.f;
	DiscoBallDashSettings.EndSpeed = 850.f;
}

class DiscoBallCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Discoball");
	default CapabilityTags.Add(n"Movement");

	default CapabilityDebugCategory = n"Discoball";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	FDiscoBallMovementSettings MoveSettings;

	UCharacterDiscoBallMovementComponent DiscoComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		DiscoComp = UCharacterDiscoBallMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

		if(IsPlayerDead(Player))
			return EHazeNetworkActivation::DontActivate;

		if(DiscoComp.DiscoBall == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(DiscoComp.DiscoBall.IsDiscoBallDestroyed())
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(IsPlayerDead(Player))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(DiscoComp.DiscoBall == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(DiscoComp.DiscoBall.IsDiscoBallDestroyed())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Cymbal", this);
		Player.BlockCapabilities(n"WeaponAim", this);
		Player.BlockCapabilities(n"SongOfLife", this);
		Player.BlockCapabilities(n"PowerfulSong", this);
		Player.ApplySettings(DiscoBallDashSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Cymbal", this);
		Player.UnblockCapabilities(n"WeaponAim", this);
		Player.UnblockCapabilities(n"SongOfLife", this);
		Player.UnblockCapabilities(n"PowerfulSong", this);
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!DiscoComp.DiscoBall.IsDiscoBallDestroyed())
			MoveComp.SetTargetFacingDirection(DiscoComp.DiscoBall.BallTravelDirection * -1.f);
		
		FHazeFrameMovement DiscoBallMove = MoveComp.MakeFrameMovement(n"DiscoBallCapability");
		
		if(HasControl())
		{
			DiscoBallMove.OverrideGroundedState(EHazeGroundedState::Grounded);
		
			// DiscoBallMove.FlagToMoveWithDownImpact();
			
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			
			FVector MoveDelta = Input * 600.f * DeltaTime;

			//Decide movement force that ball applies on player
			//Use line below if you want distance from center to affect players
			// float RollSpeed = 100.f + 150.f * (DiscoComp.DistanceFromCenter() / 500.f);
			
			float RollSpeed = 100.f + DiscoComp.DiscoBall.CurrentSpeedAlongSplinerino * 0.1f;
			// Print("PlayerRollSpeedForce: "+RollSpeed);

			FVector RollDelta = DiscoComp.DiscoBall.BallTravelDirection * RollSpeed * DeltaTime;

#if TEST
			EGodMode GodMode = GetGodMode(Player);

			if(GodMode == EGodMode::God || GodMode == EGodMode::Jesus)
			{
				RollDelta = FVector::ZeroVector;
			}
#endif // TEST
					
			DiscoBallMove.ApplyDelta(RollDelta);
			DiscoBallMove.ApplyDelta(MoveDelta);
			DiscoBallMove.ApplyTargetRotationDelta();
			MoveCharacter(DiscoBallMove, n"DiscoBall");
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbDataFinalized;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbDataFinalized);
			DiscoBallMove.ApplyConsumedCrumbData(CrumbDataFinalized);
			MoveCharacter(DiscoBallMove, n"DiscoBall");
		}
		
	

		
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}