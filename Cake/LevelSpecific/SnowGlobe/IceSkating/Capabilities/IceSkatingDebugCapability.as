import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;

class UIceSkatingDebugCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UHazeMovementComponent MoveComp;

	UIceSkatingDebugWidget Widget;
	int DebugLevel = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

	    if (DebugLevel == 0)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (DebugLevel == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Widget = Cast<UIceSkatingDebugWidget>(Player.AddWidget(SkateComp.DebugWidget));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveWidget(Widget);
		Widget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		/*
		if (WasActionStarted(ActionNames::TEMPRightStickPress))
			NetSetDebugLevel((DebugLevel + 1) % 3);
		*/
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DebugLevel > 1)
		{
			FHitResult GroundHit = SkateComp.GetGroundHit();
			FVector Loc = Player.ActorLocation;

			if (GroundHit.bBlockingHit)
			{
				// Draw ground normal
				System::DrawDebugLine(Loc, Loc + SkateComp.GroundNormal * 500.f, FLinearColor::Red);

				// Draw slope down
				FVector GroundNormal = SkateComp.GroundNormal;

				FVector SlopeRight = GroundNormal.CrossProduct(FVector::UpVector);
				FVector SlopeDown = GroundNormal.CrossProduct(SlopeRight);
				SlopeDown.Normalize();
				System::DrawDebugLine(Loc, Loc + SlopeDown * 500.f, FLinearColor::Blue);

				// Draw velocity
				FVector Velocity = MoveComp.Velocity;
				System::DrawDebugLine(Loc + FVector::UpVector * 100.f, Loc + Velocity + FVector::UpVector * 100.f, FLinearColor::Yellow);

				// Draw input
				FVector Input = SkateComp.GetScaledPlayerInput();
				FVector SlopeInput = SkateComp.TransformVectorToPlane(Input, SkateComp.GroundNormal);
				System::DrawDebugLine(Loc, Loc + SlopeInput * 500.f, FLinearColor::Gray);
			}
		}

		FVector Velocity = MoveComp.Velocity;
		FVector HoriVelocity;
		FVector VertVelocity;
		Math::DecomposeVector(VertVelocity, HoriVelocity, Velocity, SkateComp.GroundNormal);

		Widget.CurrentSpeed = Velocity.Size();
		Widget.CurrentHorizontalSpeed = HoriVelocity.Size();
		Widget.CurrentVerticalSpeed = VertVelocity.Size();
		Widget.MaxSpeed = SkateComp.MaxSpeed;
	}

	UFUNCTION(NetFunction)
	void NetSetDebugLevel(int Level)
	{
		DebugLevel = Level;
	}
}