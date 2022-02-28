import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;
import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleTags;

class UMarblePhysicsCorrectorCapability : UHazeCapability
{
	default CapabilityTags.Add(FMarbleTags::MarblePhysics);
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;
	
	AMarbleBall Marble;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Marble = Cast<AMarbleBall>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Marble.Spline != nullptr && HasControl())
        {
            return EHazeNetworkActivation::ActivateLocal;
        }
        else
        {
            return EHazeNetworkActivation::DontActivate;
        }
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Marble.Spline != nullptr && HasControl())
        {
            return EHazeNetworkDeactivation::DontDeactivate;
        }
        else
        {
            return EHazeNetworkDeactivation::DeactivateLocal;
        }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
        CorrectPhysics(DeltaTime);
	}

    void CorrectPhysics(float DeltaTime)
    {
        float DistanceAlongSpline = Marble.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
        FVector Tangentdirection = Marble.Spline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

        FVector LeftVector = Tangentdirection.CrossProduct(FVector::UpVector);

        FVector CurrentVelocity = Marble.Mesh.GetPhysicsLinearVelocity();
        FVector ZeroOutGravity = FVector::ZeroVector;
        ZeroOutGravity.X = 1;
        ZeroOutGravity.Y = 1;

        float DotCurrentVelocity =  LeftVector.GetSafeNormal().DotProduct(CurrentVelocity);
        FVector AdjustedLinearVelocity = LeftVector.GetSafeNormal() * DotCurrentVelocity * ZeroOutGravity;

        FVector CurrentVelocity2 = Marble.Mesh.GetPhysicsLinearVelocity();
        Marble.Mesh.SetPhysicsLinearVelocity(CurrentVelocity - AdjustedLinearVelocity);
    }
}