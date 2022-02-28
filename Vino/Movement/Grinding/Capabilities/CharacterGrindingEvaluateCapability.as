import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingActivationPointComponent;
import Vino.Movement.Grinding.GrindingTransferActivationPoint;

class UCharacterGrindingEvaluateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Evaluate);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;

	UHazeActivationPoint ActivationPoint_Grapple;
	UHazeActivationPoint ActivationPoint_Transfer;

	//UPROPERTY(Transient, EditConst)
	TArray<AGrindspline> NearbyGrindSplines;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);

		ActivationPoint_Grapple = UGrindingActivationComponent::GetOrCreate(Owner);
		ActivationPoint_Grapple.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		ActivationPoint_Transfer = UGrindingTransferActivationPoint::GetOrCreate(Owner);
		ActivationPoint_Transfer.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		Player.CapsuleComponent.OnComponentBeginOverlap.AddUFunction(this, n"OnCapsuleBeginOverlap");
		Player.CapsuleComponent.OnComponentEndOverlap.AddUFunction(this, n"OnCapsuleEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		if (NearbyGrindSplines.Num() > 0)
			return EHazeNetworkActivation::ActivateLocal;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (NearbyGrindSplines.Num() > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

    UFUNCTION()
    void OnCapsuleBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AGrindspline GrindSpline = Cast<AGrindspline>(OtherActor);
		if (GrindSpline == nullptr)
			return;
		if (OtherComponent != GrindSpline.NearbySplineBox)
			return;

		AddNearbyGrindSpline(GrindSpline);
    }

    UFUNCTION()
    void OnCapsuleEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AGrindspline GrindSpline = Cast<AGrindspline>(OtherActor);
		if (GrindSpline == nullptr)
			return;
		if (OtherComponent != GrindSpline.NearbySplineBox)
			return;

		RemoveNearbyGrindSpline(GrindSpline);
    }

	void AddNearbyGrindSpline(AGrindspline GrindSpline)
	{
		NearbyGrindSplines.Add(GrindSpline);
	}

	void RemoveNearbyGrindSpline(AGrindspline GrindSpline)
	{
		NearbyGrindSplines.Remove(GrindSpline);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";

		if (NearbyGrindSplines.Num() > 0)
			DebugText += "<Green>Nearby Splines:</>\n";
		else
			DebugText += "<Red>No Nearby Splines</>\n";

		for (AGrindspline GrindSpline : NearbyGrindSplines)
		{
			DebugText += "- " + GrindSpline.Name + "\n";
		}

		return DebugText;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		ReduceSplineCooldowns(DeltaTime);
		ReduceSplineLowPriorities(DeltaTime);
    }

	void ReduceSplineCooldowns(float DeltaTime)
	{
		for (int Index = UserGrindComp.GrindSplineCooldowns.Num() - 1; Index >= 0; Index--)
		{
			FGrindSplineCooldown& SplineCooldown = UserGrindComp.GrindSplineCooldowns[Index];
			SplineCooldown.Cooldown -= DeltaTime;

			if (SplineCooldown.Cooldown <= 0.f)
				UserGrindComp.GrindSplineCooldowns.RemoveAt(Index);
		}
	}
	void ReduceSplineLowPriorities(float DeltaTime)
	{
		for (int Index = UserGrindComp.GrindSplineLowPriorities.Num() - 1; Index >= 0; Index--)
		{
			FGrindSplineCooldown& SplineCooldown = UserGrindComp.GrindSplineLowPriorities[Index];
			SplineCooldown.Cooldown -= DeltaTime;

			if (SplineCooldown.Cooldown <= 0.f)
				UserGrindComp.GrindSplineLowPriorities.RemoveAt(Index);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SetCapabilityActionState(GrindingActivationEvents::PotentialGrinds, EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UserGrindComp.ValidNearbyGrindSplines.Reset();
		ConsumeAction(GrindingActivationEvents::PotentialGrinds);

		Player.SetCapabilityActionState(GrindingActivationEvents::PotentialGrinds, EHazeActionState::Inactive);
		ActivationPoint_Grapple.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TArray<AGrindspline>& PotentialValidGrindSplines = UserGrindComp.ValidNearbyGrindSplines;
		PotentialValidGrindSplines = NearbyGrindSplines;

		for (FGrindSplineCooldown GrindSplineCooldown : UserGrindComp.GrindSplineCooldowns)
		{
			PotentialValidGrindSplines.Remove(GrindSplineCooldown.GrindSpline);
		}
		
		if (UserGrindComp.HasActiveGrindSpline())
		{
			PotentialValidGrindSplines.Remove(UserGrindComp.ActiveGrindSplineData.GrindSpline);
		}
		else
		{
			if (ActivationPoint_Transfer.ValidationType != EHazeActivationPointActivatorType::None)
				ActivationPoint_Transfer.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}

		for (int IGrind = PotentialValidGrindSplines.Num() - 1; IGrind >= 0; IGrind--)
		{
			if (!PotentialValidGrindSplines[IGrind].PlayerIsAllowdToUse(Player))
				PotentialValidGrindSplines.RemoveAt(IGrind);
		}
	}
}
