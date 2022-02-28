import Vino.Animations.PoseTrailComponent;

struct FLarvaBoneRotations
{
	UPROPERTY()
	FRotator Head;
	UPROPERTY()
	FRotator Neck1;
	UPROPERTY()
	FRotator Neck;
	UPROPERTY()
	FRotator Spine3;
	UPROPERTY()
	FRotator Spine2;
	UPROPERTY()
	FRotator Spine1;
	UPROPERTY()
	FRotator Spine;
	UPROPERTY()
	FRotator Tail1;
	UPROPERTY()
	FRotator Tail2;
	UPROPERTY()
	FRotator Tail3;
	UPROPERTY()
	FRotator Tail4;
	UPROPERTY()
	FRotator Tail5;
	UPROPERTY()
	FRotator Tail6;
}

namespace LarvaPose
{
	UFUNCTION()
	void GetLarvaPose(UPoseTrailComponent PoseTrail, FLarvaBoneRotations& Pose)
	{
		if (PoseTrail == nullptr)
			return;

		PoseTrail.Pose.Find(n"Head", Pose.Head);
		PoseTrail.Pose.Find(n"Neck1", Pose.Neck1);
		PoseTrail.Pose.Find(n"Neck", Pose.Neck);
		PoseTrail.Pose.Find(n"Spine3", Pose.Spine3);
		PoseTrail.Pose.Find(n"Spine2", Pose.Spine2);
		PoseTrail.Pose.Find(n"Spine1", Pose.Spine1);
		PoseTrail.Pose.Find(n"Spine", Pose.Spine);
		PoseTrail.Pose.Find(n"Tail1", Pose.Tail1);
		PoseTrail.Pose.Find(n"Tail2", Pose.Tail2);
		PoseTrail.Pose.Find(n"Tail3", Pose.Tail3);
		PoseTrail.Pose.Find(n"Tail4", Pose.Tail4);
		PoseTrail.Pose.Find(n"Tail5", Pose.Tail5);
		PoseTrail.Pose.Find(n"Tail6", Pose.Tail6);
	}
} 
