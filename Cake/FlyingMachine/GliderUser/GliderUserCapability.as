import Cake.FlyingMachine.Glider.FlyingMachineGliderComponent;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachineGliderUserCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Glider);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default CapabilityDebugCategory = FlyingMachineCategory::Glider;

	AHazePlayerCharacter Player;
	UFlyingMachineGliderComponent Glider;
	UFlyingMachineGliderUserComponent GliderUser;

	UHazeSplineComponent Spline;
	FFlyingMachineGliderSettings Settings;

	UPROPERTY(Category = "Animation")
	UBlendSpaceBase HangBlendSpaceCody;
	
	UPROPERTY(Category = "Animation")
	UBlendSpaceBase HangBlendSpaceMay;

	float CurrentInputX = 0.f;
	float InputTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GliderUser = UFlyingMachineGliderUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GliderUser.Glider == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GliderUser.Glider == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this);
		Player.BlockMovementSyncronization(this);
		Player.BlockCameraSyncronization(this);
		
		Glider = GliderUser.Glider;
		Spline = GliderUser.Spline;

		Player.AttachToComponent(Spline);
		Player.RootComponent.RelativeRotation = FRotator(0.f, -90.f, 0.f);
		GliderUser.Position = 0.5f;

		float Blendtime = IsActioning(n"BlendSpaceGlider") ? 0.2f : 0.f;			 

		if (Player.IsCody())
		{
			Player.PlayBlendSpace(HangBlendSpaceCody, Blendtime, PlayRate = 1.9f);
		}
		else
		{
			Player.PlayBlendSpace(HangBlendSpaceMay, Blendtime, PlayRate = 1.9f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockMovementSyncronization(this);
		Player.UnblockCameraSyncronization(this);

		Glider = nullptr;
		Spline = nullptr;

		Player.DetachRootComponentFromParent();
		Player.StopBlendSpace();
	}

	UFUNCTION(NetFunction)
	void NetSendInput(float InputX)
	{
		CurrentInputX = InputX;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			InputTimer -= DeltaTime;
			if(InputTimer <= 0)
			{
				InputTimer = 0.1f;
				NetSendInput(GetAttributeVector(AttributeVectorNames::LeftStickRaw).X);
			}
		}

		float Position = GliderUser.Position;

		Player.SetBlendSpaceValues(CurrentInputX, 0.f);

		float MoveSpeed = Settings.PlayerShimmySpeed / Spline.SplineLength;

		Position += CurrentInputX * DeltaTime * MoveSpeed;

		if (Position < 0.f || Position > 1.f)
			Player.SetBlendSpaceValues(0.f, 0.f);

		Position = FMath::Clamp(Position, 0.f, 1.f);

		GliderUser.Position = Position;

		Player.RootComponent.SetRelativeLocation(Spline.GetLocationAtTime(Position, ESplineCoordinateSpace::Local));
	}
}