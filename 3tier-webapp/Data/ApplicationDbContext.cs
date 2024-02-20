using Microsoft.EntityFrameworkCore;
using _3tier_webapp.Pages;

namespace _3tier_webapp.Data
{
    public class VotingContext : DbContext
    {
        public VotingContext(DbContextOptions<VotingContext> options)
            : base(options)
        {
        }

        public DbSet<VoteOption> VoteOptions { get; set; }
    }
}