import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStoneComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;

class UCurlingStonePlayerCollisionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingStonePlayerCollisionCapability");
	default CapabilityTags.Add(n"CurlingStoneMovement");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACurlingStone CurlingStone;

	UHazeMovementComponent MoveComp;

	UCurlingStoneComponent StoneComp;

	UCurlingPlayerComp PlayerComp;

	FVector MovementForce;

	float PlayerImpulseRadius = 200.f;
	float ImpulseMultiplier = 0.3f;
	float AudioRate = 0.5f;
	float AudioTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CurlingStone = Cast<ACurlingStone>(Owner);
		MoveComp = UHazeMovementComponent::Get(CurlingStone);
		StoneComp = UCurlingStoneComponent::Get(CurlingStone);
		AudioTime = AudioRate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		PlayerDistanceCheck(DeltaTime);
	}
	
	void PlayerDistanceCheck(float DeltaTime)
	{
		float DistanceMay = (CurlingStone.ActorLocation - Game::GetMay().ActorLocation).Size();
		float DistanceCody = (CurlingStone.ActorLocation - Game::GetCody().ActorLocation).Size();

		if (DistanceMay <= PlayerImpulseRadius)
			ApplyPlayerImpulse(Game::GetMay(), DeltaTime);

		if (DistanceCody <= PlayerImpulseRadius)
			ApplyPlayerImpulse(Game::GetCody(), DeltaTime);

		if (AudioTime < AudioRate)
			AudioTime += DeltaTime;
	}

	void ApplyPlayerImpulse(AHazePlayerCharacter Player, float DeltaTime)
	{
		if (AudioTime >= AudioRate)
		{
			float PlayerVelocity = FMath::Clamp(Player.MovementComponent.Velocity.Size() / 12.f, 0.f, 250.f);
			CurlingStone.AudioOnPlayerCollideEvent(PlayerVelocity, Player);
			AudioTime = 0.f;
		}

		if (CurlingStone.GetRootComponent().GetAttachParent() != nullptr)
		{
			AHazePlayerCharacter ParentPlayer = Cast<AHazePlayerCharacter>(CurlingStone.GetRootComponent().GetAttachParent());

			if (Player == CurlingStone.OwningPlayer)
				return;
		}

		FVector Direction = Player.ActorLocation - CurlingStone.ActorLocation;
		Direction.Normalize();
		FVector Impulse;
		float UpVelocity = 0.f;
		float PlayerAirborneMultiplier = 1.f;

		if (CurlingStone.MoveComp.Velocity.Size() >= 300.f)
		{
			Impulse = Direction * (CurlingStone.MoveComp.Velocity.ConstrainToPlane(FVector::UpVector) * ImpulseMultiplier);
			UpVelocity = CurlingStone.MoveComp.Velocity.Size() * ImpulseMultiplier;
		}
		else if (Player.MovementComponent.Velocity.Size() >= 100.f)
		{
			Impulse = Direction * Player.MovementComponent.Velocity.Size() * 0.95f;
			UpVelocity = Player.MovementComponent.Velocity.Size() * 0.22f;
		}
		else
		{
			Impulse = Direction * Player.MovementComponent.Velocity.Size() * 0.15f;
			UpVelocity = Player.MovementComponent.Velocity.Size() * 0.1f;
		}
		
		if (Player.MovementComponent.IsAirborne())
			PlayerAirborneMultiplier = 0.5f;
		
		FVector FinalImpulse = Impulse + FVector(0.f, 0.f, UpVelocity);
		FinalImpulse *= PlayerAirborneMultiplier;

		Player.MovementComponent.AddImpulse(FinalImpulse);
	}
}