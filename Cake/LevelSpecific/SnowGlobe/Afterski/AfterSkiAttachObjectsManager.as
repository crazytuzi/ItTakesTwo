import Cake.LevelSpecific.SnowGlobe.SnowFolkCrowd.SnowFolkCrowdMember;

struct FMemberAndObject
{
	UPROPERTY()
	ASnowFolkCrowdMember Member;
	
	UPROPERTY()
	AHazeActor Object;
}

class AAfterSkiAttachObjectsManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<FMemberAndObject> MemberAndObjectRightH;

	UPROPERTY(Category = "Setup")
	TArray<FMemberAndObject> MemberAndObjectLeftH;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (MemberAndObjectRightH.Num() > 0)
		{
			for (FMemberAndObject Set : MemberAndObjectRightH)
			{
				Set.Object.AttachToComponent(Set.Member.SkeletalMeshComponent, n"RightHand", EAttachmentRule::SnapToTarget);
			}
		}

		if (MemberAndObjectLeftH.Num() > 0)
		{
			for (FMemberAndObject Set : MemberAndObjectLeftH)
			{
				Set.Object.AttachToComponent(Set.Member.SkeletalMeshComponent, n"LeftHand", EAttachmentRule::SnapToTarget);
			}
		}
	}
}